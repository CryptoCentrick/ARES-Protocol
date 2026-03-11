//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardDistributor {

   event RewardDistributed(address indexed account, uint amount);
   event RewardClaimed(address indexed account, uint amount);

   
   function updateRoot(bytes32 _newRoot) external;

   function distributeReward(address account, uint amount) external;

   function claimReward(address recipient, uint amount, bytes32[] calldata proof) external;

   function isClaimed (uint index) external view returns (bool);

}