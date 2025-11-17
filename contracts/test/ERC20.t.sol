// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract ERC20Test is Test {
    TestToken internal token;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal constant INITIAL_SUPPLY = 1_000 ether;

    function setUp() public {
        token = new TestToken("Test Token", "TEST", INITIAL_SUPPLY);
    }

    function testInitialSupplyAssignedToDeployer() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
    }

    function testTransferUpdatesBalances() public {
        uint256 amount = 100 ether;

        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - amount);
    }

    function testApproveAndTransferFrom() public {
        uint256 amount = 50 ether;

        token.approve(alice, amount);
        assertEq(token.allowance(address(this), alice), amount);

        vm.prank(alice);
        token.transferFrom(address(this), bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(address(this), alice), 0);
    }
}


