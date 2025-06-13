// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol"; // Import your custom ERC-20 token

/**
 * @title Staking Contract
 * @notice Allows users to stake ERC-20 tokens and earn rewards over time.
 */
contract Staking {

    MyToken public stakingToken; // The token users will stake
    uint256 public rewardRate = 1; // Fixed reward rate: 1 token per day

    // Struct to hold staking information for each user
    struct Staker {
        uint256 balance;         // Tokens currently staked
        uint256 lastStakedTime;  // Last interaction time (used to calculate rewards)
        uint256 rewards;         // Accumulated (but unclaimed) rewards
    }

    mapping(address => Staker) public stakers; // Mapping of user address to staking data

    // ========== Events ==========

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    // ========== Constructor ==========

    /**
     * @param erc20Token The address of the ERC-20 token to be staked.
     */
    constructor(address erc20Token) {
        stakingToken = MyToken(erc20Token);
    }

    // ========== External Functions ==========

     function getStakerBalance(address user) external view returns (uint256) {
          return stakers[user].balance;
     }
    /**
     * @notice Stake a certain amount of tokens.
     * @param _amount The amount to stake.
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");

        _calculateReward(msg.sender); // Update rewards before changing balance

        // Transfer staking tokens from user to contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // Update user's stake data
        stakers[msg.sender].balance += _amount;
        stakers[msg.sender].lastStakedTime = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Withdraw a portion of staked tokens.
     * @param _amount The amount to withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(stakers[msg.sender].balance >= _amount, "Not enough staked");

        _calculateReward(msg.sender); // Update rewards before reducing balance

        // Update stake balance and return tokens
        stakers[msg.sender].balance -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @notice Claim the accumulated staking rewards.
     */
    function claimReward() external {
        _calculateReward(msg.sender); // Ensure rewards are up-to-date

        uint256 reward = stakers[msg.sender].rewards;
        require(reward > 0, "No reward");

        // Reset rewards and transfer to user
        stakers[msg.sender].rewards = 0;
        stakingToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // ========== Internal Functions ==========

    /**
     * @dev Internal function to calculate pending rewards for a user.
     * Updates the `rewards` and `lastStakedTime` fields.
     * @param user Address of the user.
     */
    function _calculateReward(address user) internal {
        Staker storage staker = stakers[user];

        if (staker.balance > 0) {
            uint256 duration = block.timestamp - staker.lastStakedTime;

            // Formula: (staked amount * rewardRate * time) / 1 day
            uint256 reward = (staker.balance * rewardRate * duration) / 1 days;

            staker.rewards += reward;
            staker.lastStakedTime = block.timestamp;
        }
    }
}
