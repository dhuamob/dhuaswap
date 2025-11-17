// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Pair
 * @dev Minimal skeleton of the AMM pair contract.
 *      Implements core storage layout and public getters.
 *      Mint/Burn/Swap logic will be added in subsequent steps.
 */
contract Pair {
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of the most recent liquidity event

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _token0, address _token1) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    // Internal helper placeholders -------------------------------------------------

    function _update(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) internal {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
        emit Sync(_reserve0, _reserve1);
    }
}

