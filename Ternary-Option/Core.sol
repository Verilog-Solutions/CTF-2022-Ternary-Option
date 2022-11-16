// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ICore} from "./interfaces/ICore.sol";
import {CoreStorage} from "./CoreStorage.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title The core logic for the ternary option platform
/// @notice this contract is only valid until 1672473600(2022 Dec 31).Claim your rewards before the contract expired! After that, owner can withdraw all the funds.

contract Core is ICore, CoreStorage, ReentrancyGuard, Ownable {
    /*
    ======== Verilog CTF - Web3Dubai Conference @ 2022 =============================== 
    This is a demo decentralized ternary option platform, where users can deposit MATIC
    to join the exciting 5-min ternary option trading. To simplify the logic, we will
    only allow users to deposit 1 MATIC each time to join the game. The rule is simple:

    
            "Winner Takes All !!!!!" 

    Some detialed info:
    Each round is 5 mins
    Each account only allow 1 MATIC each round to participate in the game
    There will be 2.5 mins open to deposit + 2.5 mins for lock
    Oracle is real-time price from the Quickswap / Uniswap

    Find your way to hack around ! Good Luck !
    */
    constructor(address _pair, uint256 _openDuration, uint256 _lockDuration, uint256 _bountyAmount) {
        pair = IUniswapV2Pair(_pair);
        tokenA = pair.token0();
        tokenB = pair.token1();

        openDuration = _openDuration;
        lockupDuration = _lockDuration;
        bountyAmount = _bountyAmount;
    }

    // for receiving Matic
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* Core Functions */
    // setup the game and triger to start it
    function startGame() external override onlyOwner returns (bool) {
        RoundInfo storage round = rounds[currentRoundID];
        require(currentRoundID == 0, "only can be triggered once");
        require(round.status == 0, "only when not initialized");
        round.initTime = block.timestamp;
        round.initPrice = rate();
        round.status = 1;
        isStarted = true;
        return true;
    }

    // trigger lockup after openDuration passed
    function startLockup() external override returns (bool) {
        RoundInfo storage round = rounds[currentRoundID];
        require(round.status == 1, "only during open duration");
        require(round.initTime + openDuration <= block.timestamp, "only when time allowed");
        require(
            round.totalLongAmount != 0 && round.totalShortAmount != 0 && round.totalTieAmount != 0,
            "only when there exists bets"
        ); // check this
        round.status = 2;
        return true;
    }

    // trigger next round will increase the currentRoundID
    function startNextRound() external override returns (bool) {
        RoundInfo storage round = rounds[currentRoundID];
        require(round.status == 2, "only during the lockup duraton");
        require(round.initTime + openDuration + lockupDuration <= block.timestamp, "only when time allowed");
        // determine result
        round.finalPrice = rate();
        uint256 delta = round.initPrice / 10; // check this
        uint256 totalAmount = round.totalLongAmount + round.totalShortAmount + round.totalTieAmount;
        if (round.finalPrice > round.initPrice + delta) {
            // long win
            round.result = 1;
            round.payOutRatio = totalAmount * PRECISION / round.totalLongAmount;
        } else if (round.finalPrice + delta < round.initPrice) {
            // short win
            round.result = 2;
            round.payOutRatio = totalAmount * PRECISION / round.totalShortAmount;
        } else {
            // tie win
            round.result = 3;
            round.payOutRatio = totalAmount * PRECISION / round.totalTieAmount;
        }

        // iterate through current round players & update winner's player info
        for (uint256 i = 0; i < currentRoundPlayers[currentRoundID].length; ++i) {
            address player_address = currentRoundPlayers[currentRoundID][i];
            PlayerInfo storage player = players[player_address];
            if (player.position[currentRoundID] == round.result) {
                // update winner info
                player.consecutivelWinningAmount += 1;
                if (player.consecutivelWinningAmount == 3) {
                    // if consecutively win more than 3 time
                    topPlayers.push(player_address);
                    isTopPlayers[player_address] = true;
                }
            } else {
                player.consecutivelWinningAmount = 0;
                if (isTopPlayers[player_address] == true) {
                    // if player is a top player or not
                    for (uint256 j = 0; j < topPlayers.length; ++j) {
                        if (topPlayers[j] == player_address) {
                            // find it and remove from topPlayer list
                            topPlayers[j] = topPlayers[topPlayers.length - 1];
                            isTopPlayers[player_address] = false;
                            topPlayers.pop();
                        }
                    }
                }
            }
        }

        // setup next round
        currentRoundID += 1;
        rounds[currentRoundID].initTime = block.timestamp;
        rounds[currentRoundID].initPrice = rate();
        rounds[currentRoundID].status = 1;
        return true;
    }

    /* User Interaction Functions */
    // user join the current game round
    function joinRound(uint256 _position) external payable override returns (bool) {
        RoundInfo storage round = rounds[currentRoundID];
        PlayerInfo storage player = players[msg.sender];
        require(msg.value >= TICKET_PRICE);
        require(round.status == 1, "only can deposit in open time");
        require(
            round.initTime <= block.timestamp && round.initTime + openDuration >= block.timestamp, "only in open window"
        );
        require(_position >= 1 && _position <= 3, "position within a range");
        require(player.position[currentRoundID] == 0, "Already entered");
        // add players to array
        currentRoundPlayers[currentRoundID].push(msg.sender);
        // setting the player info
        player.position[currentRoundID] = _position;
        // setting the round info
        if (_position == 1) {
            round.totalLongAmount += 1;
        }
        if (_position == 2) {
            round.totalShortAmount += 1;
        }
        if (_position == 3) {
            round.totalTieAmount += 1;
        }
        return true;
    }

    // user claim their previous round rewards
    function claimRoundReward(uint256 _roundID) external payable override nonReentrant returns (bool) {
        RoundInfo memory round = rounds[_roundID];
        PlayerInfo storage player = players[msg.sender];
        require(_roundID < currentRoundID, "only past round");
        require(round.result == player.position[_roundID], "only when winning");
        require(player.isClaimed[_roundID] == false, "already claimed");
        // change player state
        player.isClaimed[_roundID] = true;
        // send rewards
        uint256 payout = TICKET_PRICE * round.payOutRatio / PRECISION;
        TransferHelper.safeTransferETH(msg.sender, payout);

        return true;
    }

    // consective 6 round winners can claim the big bounty. only 1 bounty reward
    function claimBounty() external payable override nonReentrant returns (bool) {
        /*
    what if there are more than 1 winners:
            "First come first serve"
     */
        require(isBountyClaimed == false, "only can be claimed once");
        require(isTopPlayers[msg.sender] == true, "only top player can get");
        require(players[msg.sender].consecutivelWinningAmount >= 6, "only consectively won 6 time");
        TransferHelper.safeTransferETH(msg.sender, bountyAmount);
        isBountyClaimed = true;
        winner = msg.sender;
        return true;
    }

    /* helpers functions */
    function rate() public view override returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 _rate = uint256(_reserve0 * PRECISION / _reserve1);
        return _rate;
    }

    /* view functions */
    function getTopPlayers() external view override returns (address[] memory _topPlayers) {
        _topPlayers = topPlayers;
    }

    function getTopPlayersLen() external view returns (uint256 len) {
        len = topPlayers.length;
    }

    function getCurrentRoundPlayers() external view override returns (address[] memory _currentRoundPlayers) {
        _currentRoundPlayers = currentRoundPlayers[currentRoundID];
    }

    function getRoundPlayerLen(uint256 roundId) external view returns (uint256 len) {
        len = currentRoundPlayers[roundId].length;
    }

    function getCurrentRoundPlayersPositions() external view override returns (uint256[] memory _positions) {
        uint256 length = currentRoundPlayers[currentRoundID].length;
        uint256[] memory positions = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            positions[i] = players[currentRoundPlayers[currentRoundID][i]].position[currentRoundID];
        }

        return (positions);
    }

    function getConsecutiveWins(address _player) external view override returns (uint256 _wins) {
        _wins = players[_player].consecutivelWinningAmount;
    }

    function getCurrentRoundInfo() external view override returns (CoreStorage.RoundInfo memory _info) {
        _info = rounds[currentRoundID];
    }

    function isFinalWinnerRevealed() external view override returns (bool result) {
        for (uint256 i = 0; i < topPlayers.length; ++i) {
            if (players[topPlayers[i]].consecutivelWinningAmount == 6) {
                result = true;
            }
        }
    }

    /// @notice pool owner can withdraw all the funds after 2022 Nov 20 12:00 PM
    /// @notice This function is not witnin the CTF attack surface, only for admin purposes
    function withdraw(address token) external onlyOwner {
        // require(block.timestamp >= 1668974400, "pool not expired!");
        if (token == address(0)) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            TransferHelper.safeTransfer(token, msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice pool owner can set the initTime of current round to avoid deadlock
    /// @notice This function is not witnin the CTF attack surface, only for admin purposes
    function setInitTime(uint256 targetTime) external onlyOwner {
        RoundInfo storage round = rounds[currentRoundID];
        round.initTime = targetTime;
    }
}
