pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;
  uint256 public deadline = block.timestamp + 60 seconds;
  uint256 public threshold = 1 ether;

  mapping(address => uint256) public balances;
  event Stake(address from, uint256 amount);

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    address from = msg.sender;
    // amount of wei
    uint256 amount = msg.value;
    require(amount > 0, 'Not enough amount');
    balances[from] += amount;

    emit Stake(from, amount);
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public deadlineReached(true) stakeNotCompleted {
    uint256 currentBalance = address(this).balance;
    bool reached = currentBalance >= threshold;

    require(reached, 'balance not reached');

    bool isCompleted = exampleExternalContract.completed();
    console.log('isCompleted', isCompleted);

    exampleExternalContract.complete{value: currentBalance}();
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public payable deadlineReached(true) stakeNotCompleted {
    address from = msg.sender;
    uint256 balance = balances[from];
    require(balance > 0, 'Not have balance');

    balances[from] = 0;

    (bool sent, bytes memory data) = from.call{value: balance}('');
    require(sent, 'Failed to send Ether');
  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    this.stake{value: msg.value}();
  }

  modifier canWithdraw() {
    console.log('Withdraw');
    uint256 currentBalance = address(this).balance;
    bool haveTime = timeLeft() > 0;
    bool reached = (currentBalance / 1 ether) >= threshold;

    require(!haveTime && !reached, "Can't withdraw");
    _;
  }

  modifier deadlineReached(bool reached) {
    uint256 time = timeLeft();

    if (reached) {
      require(time == 0, 'Deadline in not reached');
    } else {
      require(time > 0, 'Deadline already reached');
    }

    _;
  }
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, 'staking process already completed');
    _;
  }
}
