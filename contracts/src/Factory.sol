// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pair.sol";

/**
 * @title Factory
 * @dev Keeps track of deployed trading pairs and protocol fees.
 */
contract Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) private pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairIndex);

    error IdenticalAddresses();
    error ZeroAddress();
    error PairAlreadyExists(address pair);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /**
     * @notice Deploys a new trading pair contract for the provided token addresses.
     * @dev Tokens are sorted to avoid duplicate pairs with inverted order.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();

        if (pairs[token0][token1] != address(0)) {
            revert PairAlreadyExists(pairs[token0][token1]);
        }

        pair = address(new Pair(token0, token1));

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPair(address tokenA, address tokenB) external view returns (address) {
        return pairs[tokenA][tokenB];
    }
}

