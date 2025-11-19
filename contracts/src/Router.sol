// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Factory.sol";
import "./Pair.sol";

/**
 * @title Router
 * @dev Minimal router contract — facilitates liquidity management and token swaps
 */
contract Router {
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

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
        address pairAddr = _getOrCreatePair(tokenA, tokenB);
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
        require(to != address(0), "Router: INVALID_TO");
        address pairAddr = Factory(factory).getPair(tokenA, tokenB);
        require(pairAddr != address(0), "Router: PAIR_NOT_FOUND");

        IERC20(pairAddr).transferFrom(msg.sender, pairAddr, liquidity);
        (uint amount0, uint amount1) = Pair(pairAddr).burn(to);

        address token0 = Pair(pairAddr).token0();
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= amountAMin && amountB >= amountBMin, "Router: INSUFFICIENT_OUTPUT");
        emit RemoveLiquidity(msg.sender, tokenA, tokenB, amountA, amountB, pairAddr);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        require(path.length >= 2, "Router: INVALID_PATH");
        require(to != address(0), "Router: INVALID_TO");

        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        address pairAddr = Factory(factory).getPair(path[0], path[1]);
        require(pairAddr != address(0), "Router: PAIR_NOT_FOUND");
        IERC20(path[0]).transferFrom(msg.sender, pairAddr, amountIn);

        for (uint i = 0; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            pairAddr = Factory(factory).getPair(input, output);
            require(pairAddr != address(0), "Router: PAIR_NOT_FOUND");

            uint amountOut = _getAmountOut(amounts[i], pairAddr, input);
            amounts[i + 1] = amountOut;

            (address token0,) = _sortTokens(input, output);
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address recipient = i < path.length - 2 ? Factory(factory).getPair(output, path[i + 2]) : to;
            require(recipient != address(0), "Router: RECIPIENT_PAIR_NOT_FOUND");

            Pair(pairAddr).swap(amount0Out, amount1Out, recipient);
        }

        require(amounts[path.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT");
        address lastPair = Factory(factory).getPair(path[path.length - 2], path[path.length - 1]);
        emit Swap(msg.sender, path[0], path[path.length - 1], amountIn, amounts[path.length - 1], lastPair);
    }

    function _getOrCreatePair(address tokenA, address tokenB) internal returns (address pairAddr) {
        pairAddr = Factory(factory).getPair(tokenA, tokenB);
        if (pairAddr == address(0)) {
            pairAddr = Factory(factory).createPair(tokenA, tokenB);
        }
    }

    function _sortTokens(address tokenA, address tokenB) private pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Router: ZERO_ADDRESS");
    }

    function _getAmountOut(uint amountIn, address pairAddr, address input) private view returns (uint amountOut) {
        (uint112 reserve0, uint112 reserve1,) = Pair(pairAddr).getReserves();
        (uint reserveIn, uint reserveOut) = input == Pair(pairAddr).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Router: INSUFFICIENT_LIQUIDITY");

        uint amountInWithFee = amountIn * FEE_NUMERATOR;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
