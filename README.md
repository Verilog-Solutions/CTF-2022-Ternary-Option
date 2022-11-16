<div align="center">
  <img alt="verilog logo" src="https://raw.githubusercontent.com/Verilog-Solutions/.github/main/assets/verilog-logo.svg" width="300"  />
  <p align="center">
    <a href="https://github.com/sindresorhus/awesome">
      <img alt="awesome list badge" src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg">
    </a>
  </p>

  <p align="center">Verilog Web3Dubai CTF Challenge #1 </p>

</div>

---
## Introduction
| Verilog 2022 web3dubai CTF challenge #1
  
  This is a demo decentralized ternary option platform, where users can deposit MATIC
  to join the exciting 5-min ternary option trading. To simplify the logic, we will
  only allow users to deposit 1 MATIC each time to join the game. The rule is simple:

  
            "Winner Takes All !!!!!" 

  
  - Some detialed info:
  - Each round is 5 mins
  - Each account only allows 1 MATIC each round to participate in the game
  - There will be 4 mins open to deposit + 1 mins for lock
  - Oracle is real-time price from the Quickswap / Uniswap


## Explanation

```solidity

  | startGame() | --------------- | startLockup() | --------------- | startNextRound() |
                                        |                                  |
                                         ----------------------------------

```

- Core Functions

  ```solidity
  /* Core Functions of the Binary Option Protocol Management */
  function startGame() external returns (bool);
  
  function startLockup() external returns (bool);
  
  function startNextRound() external returns (bool);
  ```

- User Interacred Actions
  ```solidity
  /* Core Functions for User Interaction */
  function joinRound(uint256 _position) external payable returns (bool);

  function claimRoundReward(uint256 _roundID) external payable returns (bool);

  function claimBounty() external payable returns (bool);
  ```



