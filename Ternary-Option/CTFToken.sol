// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CTFToken is ERC20 {
    constructor() ERC20("CTF-Token", "V-CTF-2022") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
