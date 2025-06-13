// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/Staking.sol";

contract StakingTest is Test {

     MyToken token;
     Staking staking;
     address owner = address(1);
     address staker = address(2);

     uint initialSupply = 1_000_000 * 1e18;

     function setUp() public {
        vm.startPrank(owner);
        token = new MyToken();
        staking = new Staking(address(token));

        // send tokens to staker and staking contract
        token.transfer(staker,100_000 * 1e18);
        token.transfer(address(staking), 500_000 * 1e18); // fund contract for rewards distribution
        vm.stopPrank();

        vm.startPrank(staker);
        token.approve(address(staking), type(uint).max); // allow staking
        vm.stopPrank();

     }
     
    function testStakeTokens() public {
        vm.startPrank(staker);
        staking.stake(10_000 * 1e18);
        (, , uint rewards) = staking.stakers(staker);

        assertEq(token.balanceOf(staker),90_000 * 1e18);
        assertEq(staking.getStakerBalance(staker), 10_000 * 1e18);

        assertEq(rewards, 0);
        vm.stopPrank();
    }
    function testRewardAccrualOverTime() public {
        vm.startPrank(staker);
        staking.stake(1_000 * 1e18);

        //fast forward 1 day
        vm.warp(block.timestamp + 1 days);
        staking.claimReward();

        // 1000 tokens * 1 reward rate * 1 day = 1000 reward
        assertEq(token.balanceOf(staker), 100_000 * 1e18);
        vm.stopPrank();

    }
    function testWithdrawStake() public {
        vm.startPrank(staker);
        staking.stake(2_000 * 1e18);

        vm.warp(block.timestamp + 2 days);
        staking.withdraw(1_000 * 1e18);

        assertEq(token.balanceOf(staker), 99_000 * 1e18);
        assertEq(staking.getStakerBalance(staker), 1_000 * 1e18);
        vm.stopPrank();
    }
    function testDoubleClaimRevertIfNoReward() public {
        vm.startPrank(staker);
        staking.stake(3_000 * 1e18);

        // claim right away(should revert)
        vm.expectRevert("No reward");
        staking.claimReward();
        vm.stopPrank();
    }
    function  testAccurateRewardOverMultipleClaims() public {
        vm.startPrank(staker);
        staking.stake(1_000 * 1e18);

        vm.warp(block.timestamp + 1 days);
        staking.claimReward();

        vm.warp(block.timestamp + 1 days);
        staking.claimReward();

        assertEq(token.balanceOf(staker), 101_000 * 1e18);
        vm.stopPrank();
    }

}