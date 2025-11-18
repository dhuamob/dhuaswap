// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";

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
        // TODO: implement next step
        revert("Router: not implemented");
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
