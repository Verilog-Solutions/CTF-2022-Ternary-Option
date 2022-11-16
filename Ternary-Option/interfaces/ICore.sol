// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {CoreStorage} from "../CoreStorage.sol";

/// @title The primary interface for Core contract

interface ICore {
    /* Core Functions of the Binary Option Protocol Management */
    function startGame() external returns (bool);

    function startLockup() external returns (bool);

    function startNextRound() external returns (bool);

    /* Core Functions for User Interaction */
    function joinRound(uint256 _position) external payable returns (bool);

    function claimRoundReward(uint256 _roundID) external payable returns (bool);

    function claimBounty() external payable returns (bool);

    /* view functions */
    function rate() external view returns (uint256);

    function getTopPlayers() external view returns (address[] memory _topPlayers);

    function getCurrentRoundPlayers() external view returns (address[] memory _currentRoundPlayers);

    function getCurrentRoundPlayersPositions() external view returns (uint256[] memory _positions);

    function getConsecutiveWins(address _player) external view returns (uint256 _wins);

    function getCurrentRoundInfo() external view returns (CoreStorage.RoundInfo memory _info);

    function isFinalWinnerRevealed() external view returns (bool result);
}
