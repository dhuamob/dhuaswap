// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Pair.sol";
import "../src/Factory.sol";
import "../src/Router.sol";
import "../src/ERC20.sol";

contract MockToken is TestToken {
    constructor(string memory _name, string memory _symbol, uint256 _sup) TestToken(_name, _symbol, 0) {}
    function mintTo(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract PairBaseTest is Test {
    MockToken token0;
    MockToken token1;
    Pair pair;
    address alice = address(0xA11ce);
    address bob = address(0xB0B);

    function setUp() public virtual {
        token0 = new MockToken("T0", "T0", 0);
        token1 = new MockToken("T1", "T1", 0);
        pair = new Pair(address(token0), address(token1));
        // Mint to users
        token0.mintTo(alice, 500_000 ether);
        token1.mintTo(alice, 500_000 ether);
        token0.mintTo(bob, 500_000 ether);
        token1.mintTo(bob, 500_000 ether);
        // Approve pair
        vm.startPrank(alice);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
        vm.stopPrank();
        vm.startPrank(bob);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
        vm.stopPrank();
        vm.deal(alice, 1 ether); vm.deal(bob, 1 ether);
    }
}

contract PairMintBurnTest is PairBaseTest {
    function testMintInitialAndBurnAll() public {
        vm.startPrank(alice);
        token0.transfer(address(pair), 1000 ether);
        token1.transfer(address(pair), 2000 ether);
        pair.mint(alice);
        assertGt(pair.balanceOf(alice), 0);
        assertEq(pair.balanceOf(address(0)), 1000, "Minimum locked liquidity");
    // Burn all LP
    uint256 aliceLP = pair.balanceOf(alice);
    pair.transfer(address(pair), aliceLP);

    // compute expected returned amounts using the same integer math as Pair.burn
    uint256 pairBalance0 = token0.balanceOf(address(pair));
    uint256 pairBalance1 = token1.balanceOf(address(pair));
    uint256 totalLP = pair.totalSupply();
    uint256 expected0 = (aliceLP * pairBalance0) / totalLP;
    uint256 expected1 = (aliceLP * pairBalance1) / totalLP;

    // capture returned amounts from burn
    (uint256 amount0Returned, uint256 amount1Returned) = pair.burn(alice);

    assertEq(amount0Returned, expected0, "returned token0 matches expected");
    assertEq(amount1Returned, expected1, "returned token1 matches expected");

    // final balances should equal initial - deposited + returned
    assertEq(token0.balanceOf(alice), 500_000 ether - 1000 ether + expected0);
    assertEq(token1.balanceOf(alice), 500_000 ether - 2000 ether + expected1);
        vm.stopPrank();
    }
    function testMintAddsProportionalLP() public {
        vm.startPrank(alice);
        token0.transfer(address(pair), 100 ether);
        token1.transfer(address(pair), 100 ether);
        pair.mint(alice);
        token0.transfer(address(pair), 10 ether);
        token1.transfer(address(pair), 10 ether);
        pair.mint(alice);
        assertGt(pair.totalSupply(), 100 ether);
        vm.stopPrank();
    }
}

contract PairSwapTest is PairBaseTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(alice);
        token0.transfer(address(pair), 1000 ether);
        token1.transfer(address(pair), 1000 ether);
        pair.mint(alice);
        vm.stopPrank();
    }
    function testSwap0To1KeepsInvariantAndTakesFee() public {
        uint112 r0; uint112 r1; uint32 ts;
        (r0,r1,ts) = pair.getReserves();
        uint256 prevT1 = token1.balanceOf(bob);
        vm.startPrank(bob);
        token0.transfer(address(pair), 100 ether);
        uint256 dx = 100 ether;
        uint256 x = r0;
        uint256 y = r1;
        uint256 numerator = dx * 997 * y;
        uint256 denominator = (x * 1000) + (dx * 997);
        uint256 dy = numerator / denominator;
        pair.swap(0, dy, bob);
        vm.stopPrank();
        assertEq(token1.balanceOf(bob) - prevT1, dy, "Bob T1 out matches");
        (r0, r1,) = pair.getReserves();
        uint256 kPrev = x * y;
        uint256 kNow = uint256(r0) * uint256(r1);
        assertGt(kNow, kPrev, "k should increase due to fee accumulation");
    }
    function testSwap1To0KeepsInvariant() public {
        uint112 r0; uint112 r1; uint32 ts;
        (r0,r1,ts) = pair.getReserves();
        vm.startPrank(bob);
        token1.transfer(address(pair), 123 ether);
        uint256 dx = 123 ether;
        uint256 x = r1;
        uint256 y = r0;
        uint256 numerator = dx * 997 * y;
        uint256 denominator = (x * 1000) + (dx * 997);
        uint256 dy = numerator / denominator;
        pair.swap(dy, 0, bob);
        vm.stopPrank();
        (r0, r1,) = pair.getReserves();
        assertTrue(uint256(r0) * uint256(r1) > y * x, "K increases");
    }
}

contract PairEdgeTest is PairBaseTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(alice);
        token0.transfer(address(pair), 1000 ether);
        token1.transfer(address(pair), 1000 ether);
        pair.mint(alice);
        vm.stopPrank();
    }
    function testMintRevertsZeroInput() public {
        vm.expectRevert();
        pair.mint(alice);
    }
    function testSwapRevertsInsufficientInput() public {
        vm.expectRevert();
        pair.swap(0, 1 ether, bob);
    }
    function testCannotSwapBothDirections() public {
        vm.startPrank(bob);
        token0.transfer(address(pair), 10 ether);
        token1.transfer(address(pair), 10 ether);
        vm.expectRevert();
        pair.swap(1 ether, 1 ether, bob);
        vm.stopPrank();
    }
}

contract RouterAddLiquidityTest is Test {
    MockToken token0;
    MockToken token1;
    Factory factory;
    Router router;
    address alice = address(0xA11ce);

    function setUp() public {
        token0 = new MockToken("T0", "T0", 0);
        token1 = new MockToken("T1", "T1", 0);
        factory = new Factory(address(this));
        router = new Router(address(factory));
        // Mint tokens to alice
        token0.mintTo(alice, 10_000 ether);
        token1.mintTo(alice, 10_000 ether);
        // Alice approves Router
        vm.startPrank(alice);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function testRouterAddLiquidityCreatesPairAndMintsLP() public {
        vm.startPrank(alice);
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(token0),
            address(token1),
            1000 ether,
            2000 ether,
            0,0,
            alice);
        vm.stopPrank();
        address pairAddr = factory.getPair(address(token0), address(token1));
        assertTrue(pairAddr != address(0), "Pair should be created");
        assertEq(token0.balanceOf(pairAddr), 1000 ether);
        assertEq(token1.balanceOf(pairAddr), 2000 ether);
        assertGt(Pair(pairAddr).balanceOf(alice), 0);
        // Events can be checked with expectEmit if needed
    }
}
