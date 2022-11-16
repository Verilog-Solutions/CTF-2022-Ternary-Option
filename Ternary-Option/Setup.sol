// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Core} from "./Core.sol";

contract Setup {
    address tokenA_ = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address tokenB_ = 0xE1DBD6aB3375bfaa5868cAa047e314ACB4eAB0b6;
    address pair_ = 0x00F48D1D7613Bc16868bA999243Db98D48eCb2DB;
    uint256 openDuration_ = 240;
    uint256 lockDuration_ = 60;
    uint256 bountyAmount_ = 10 ether;
    Core public core_address;

    constructor() {
        core_address = new Core(pair_, openDuration_, lockDuration_, bountyAmount_);
        core_address.transferOwnership(msg.sender);
    }

    function isGameFinished() public view returns (bool) {
        return core_address.isFinalWinnerRevealed();
    }
}
