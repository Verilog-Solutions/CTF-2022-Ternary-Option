// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title The primary interface for Core contract

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}
