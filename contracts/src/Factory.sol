// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Factory
 * @dev Keeps track of deployed trading pairs and protocol fees.
 * This minimal version only declares the core storage layout.
 */
contract Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    // createPair + related logic will be added in the next step.
}


