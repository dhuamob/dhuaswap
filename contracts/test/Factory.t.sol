// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/Pair.sol";

contract FactoryTest is Test {
    Factory internal factory;

    address internal constant TOKEN_A = address(0xA1);
    address internal constant TOKEN_B = address(0xB2);
    address internal constant TOKEN_C = address(0xC3);

    function setUp() public {
        factory = new Factory(address(this));
    }

    function testCreatePairStoresMappingsAndArray() public {
        address pair = factory.createPair(TOKEN_A, TOKEN_B);

        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.getPair(TOKEN_A, TOKEN_B), pair);
        assertEq(factory.getPair(TOKEN_B, TOKEN_A), pair);
        assertEq(factory.allPairs(0), pair);
    }

    function testCreatePairSortsTokens() public {
        address pair = factory.createPair(TOKEN_B, TOKEN_A); // deliberately reversed
        Pair pairContract = Pair(pair);

        assertEq(pairContract.token0(), TOKEN_A);
        assertEq(pairContract.token1(), TOKEN_B);
    }

    function testCreatePairRevertsForIdenticalTokens() public {
        vm.expectRevert(Factory.IdenticalAddresses.selector);
        factory.createPair(TOKEN_A, TOKEN_A);
    }

    function testCreatePairRevertsForZeroAddress() public {
        vm.expectRevert(Factory.ZeroAddress.selector);
        factory.createPair(TOKEN_A, address(0));
    }

    function testCreatePairRevertsForDuplicatePair() public {
        address pair = factory.createPair(TOKEN_A, TOKEN_B);

        vm.expectRevert(abi.encodeWithSelector(Factory.PairAlreadyExists.selector, pair));
        factory.createPair(TOKEN_B, TOKEN_A);
    }

    function testAllPairsLengthTracksMultiplePairs() public {
        factory.createPair(TOKEN_A, TOKEN_B);
        factory.createPair(TOKEN_A, TOKEN_C);

        assertEq(factory.allPairsLength(), 2);
    }
}


