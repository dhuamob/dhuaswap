// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Pair
 * @dev Temporary minimal pair placeholder storing token addresses.
 *      Full AMM logic will be implemented in later steps.
 */
contract Pair {
    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
}


