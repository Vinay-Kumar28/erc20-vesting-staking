// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Vesting
 * @dev Token vesting contract with cliff and linear release.
 */
contract Vesting is Ownable {
    MyToken public token;

    constructor(address _tokenAdd) Ownable(msg.sender) {
        token = MyToken(_tokenAdd); // Set the ERC20 token to be vested
    }

    // Represents the vesting schedule for a single user
    struct VestingSchedule {
        uint256 totalToken;   // Total tokens allocated for vesting
        uint256 startTime;    // Start time of vesting
        uint256 cliff;        // Cliff duration (in seconds)
        uint256 duration;     // Total duration of vesting (in seconds)
        uint256 claimed;      // Amount of tokens already claimed
    }

    mapping(address => VestingSchedule) public schedules;

    // ========== Events ==========

    event VestingAdded(address indexed user, uint256 amount, uint256 cliffDuration, uint256 duration);
    event TokenClaimed(address indexed user, uint256 amount);

    // ========== Owner Functions ==========

    /**
     * @notice Creates a vesting schedule for a user
     * @param user Address receiving the vested tokens
     * @param amt Total tokens to be vested
     * @param cliffDuration Time before tokens become claimable (in seconds)
     * @param _duration Total vesting period (must be >= cliff)
     */
    function addVesting(address user, uint256 amt, uint256 cliffDuration, uint256 _duration)
        external
        onlyOwner
    {
        require(schedules[user].totalToken == 0, "Vesting already exists");
        require(_duration > 0 && cliffDuration <= _duration, "Invalid duration");

        schedules[user] = VestingSchedule({
            totalToken: amt,
            startTime: block.timestamp,
            cliff: cliffDuration,
            duration: _duration,
            claimed: 0
        });

        emit VestingAdded(user, amt, cliffDuration, _duration);
    }

    // ========== User Functions ==========

    /**
     * @notice Claim vested tokens
     * @param amt Amount of tokens to claim
     */
    function claimTokens(uint256 amt) external {
        VestingSchedule storage schedule = schedules[msg.sender];
        require(schedule.totalToken > 0, "No vesting schedule");
        require(block.timestamp >= schedule.startTime + schedule.cliff, "Cliff not reached");

        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 vested;

        if (block.timestamp >= schedule.startTime + schedule.duration) {
            // All tokens are fully vested
            vested = schedule.totalToken;
        } else {
            // Linear vesting calculation
            vested = (schedule.totalToken * timeElapsed) / schedule.duration;
        }

        uint256 claimable = vested - schedule.claimed;

        require(amt > 0, "Amount must be greater than zero");
        require(claimable >= amt, "Not enough vested tokens");

        schedule.claimed += amt;
        token.transfer(msg.sender, amt);

        emit TokenClaimed(msg.sender, amt);
    }

    // ========== View Functions ==========

    /**
     * @notice Returns total vested tokens for a user (including claimed)
     */
    function getVestedTokens(address user) external view onlyOwner returns (uint256) {
        VestingSchedule storage schedule = schedules[user];
        require(schedule.totalToken > 0, "No vesting schedule found");
        require(block.timestamp >= schedule.startTime + schedule.cliff, "Cliff not reached");

        if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalToken;
        }

        uint256 timeElapsed = block.timestamp - schedule.startTime;
        return (schedule.totalToken * timeElapsed) / schedule.duration;
    }

    /**
     * @notice Returns claimable tokens for the caller (vested - claimed)
     */
    function getClaimableTokens() external view returns (uint256) {
        VestingSchedule storage schedule = schedules[msg.sender];
        require(schedule.totalToken > 0, "No vesting schedule");
        require(block.timestamp >= schedule.startTime + schedule.cliff, "Cliff not reached");

        uint256 vested;
        uint256 timeElapsed = block.timestamp - schedule.startTime;

        if (block.timestamp >= schedule.startTime + schedule.duration) {
            vested = schedule.totalToken;
        } else {
            vested = (schedule.totalToken * timeElapsed) / schedule.duration;
        }

        return vested - schedule.claimed;
    }
}
