// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";
import "./Pair.sol"; // Added for Pair contract
import "./IERC20.sol"; // Added for IERC20 contract

/**
 * @title Router
 * @dev Minimal router contract — facilitates liquidity management and token swaps
 */
contract Router {
    address public immutable factory;
    
    event AddLiquidity(address indexed user, address indexed tokenA, address indexed tokenB, uint amountA, uint amountB, address pair);
    event RemoveLiquidity(address indexed user, address indexed tokenA, address indexed tokenB, uint amountA, uint amountB, address pair);
    event Swap(address indexed sender, address indexed tokenIn, address indexed tokenOut, uint amountIn, uint amountOut, address pair);

    constructor(address _factory) {
        factory = _factory;
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        // Minimal logic: use desired amounts as-is, find or create pair, transfer tokens, and mint
        require(to != address(0), "Router: INVALID_TO");
        require(amountADesired > 0 && amountBDesired > 0, "Router: INSUFFICIENT_AMOUNTS");
        address pairAddr = Factory(factory).getPair(tokenA, tokenB);
        if (pairAddr == address(0)) {
            pairAddr = Factory(factory).createPair(tokenA, tokenB);
        }
        // Transfer desired amounts to pair
        IERC20(tokenA).transferFrom(msg.sender, pairAddr, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pairAddr, amountBDesired);
        // Mint liquidity
        liquidity = Pair(pairAddr).mint(to);
        // For minimal version, accept that all desired amounts are used
        amountA = amountADesired;
        amountB = amountBDesired;
        emit AddLiquidity(msg.sender, tokenA, tokenB, amountA, amountB, pairAddr);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB) {
        revert("Router: not implemented");
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        revert("Router: not implemented");
    }
}
