// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
    function stake(address user, uint256 amount) external;

    function withdraw(address user, uint256 amount) external;

    function getReward(address user) external returns (uint256);

    function rewardsToken() external view returns (address);
}
