// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";

/// @title The primary persistent storage for Core contract

contract CoreStorage {
    // ------------------------------ struct -------------------------------------
    /* Game Player Info */
    struct PlayerInfo {
        /*
        unlike conventional ternary option, we have a low liquidity protection here
        market movement = final price - initial price 
        if abs(market movement) is less than 10% -> we think it is a tie
        if market movement is > 10% -> long win
        if market movement is < -10% -> short win 
         */
        uint256 consecutivelWinningAmount;
        mapping(uint256 => uint256) position;
        mapping(uint256 => bool) isClaimed;
    }

    /* Game Round Info */
    struct RoundInfo {
        uint256 initTime;
        uint256 initPrice;
        uint256 finalPrice;
        uint256 totalLongAmount;
        uint256 totalShortAmount;
        uint256 totalTieAmount;
        uint256 payOutRatio; // with 1e18 precision
        /*

        Procedure illustration:
        |- betting time 2.5 mins -|- no betting time 2.5 mins | 
        status categories:
        0 - havn't started
        1 - waiting round starts, init_Prince recorded
        2 - no betting time triggered
        3 - final_price recorded, game finished

        result categories:
        0 - no resilt
        1 - long win
        2 - short
        3 - tie
         */
        uint256 status;
        uint256 result;
    }

    // ------------------------------ Variables -------------------------------------
    uint256 constant PRECISION = 1e18;
    uint256 constant TICKET_PRICE = 1 ether;

    IUniswapV2Pair public pair;
    address public tokenA;
    address public tokenB;
    address public winner;

    // public variables
    bool public isStarted;
    bool public isBountyClaimed;

    address[] public topPlayers;

    uint256 public currentRoundID;

    uint256 public openDuration;
    uint256 public lockupDuration;
    uint256 public bountyAmount; // bounty for consecutive 6 rounds winners

    // mappings
    mapping(uint256 => address[]) currentRoundPlayers;
    mapping(address => bool) public isTopPlayers;
    mapping(address => PlayerInfo) public players;
    mapping(uint256 => RoundInfo) public rounds;

    // ------------------------------ Errors -------------------------------------
    // errors
    error CallFailed();

    // ------------------------------ Events -------------------------------------
    // event
    event Received(address indexed src, uint256 amount);
}
