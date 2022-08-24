pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;
  uint256 public deadline = block.timestamp + 30 seconds;
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
  function execute() public canExecute {
    (bool sent, ) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature('complete()'));
    require(sent, 'exampleExternalContract.complete failed');
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public payable canWithdraw {
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
    uint256 currentBalance = address(this).balance;
    bool haveTime = timeLeft() > 0;
    bool reached = (currentBalance / 1 ether) >= threshold;

    require(!haveTime && !reached, "Can't withdraw");
    _;
  }

  modifier canExecute() {
    uint256 currentBalance = address(this).balance;
    bool haveTime = timeLeft() > 0;
    bool reached = currentBalance >= threshold;
    //bool isCompleted = exampleExternalContract.completed();
    console.log(haveTime);
    console.log(currentBalance);
    console.log(reached);

    require(!haveTime && reached, "Can't execute");
    _;
  }
}
