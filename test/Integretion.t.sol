// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/Vesting.sol";
import "../src/Staking.sol";

contract IntegrationTest is Test {
    MyToken token;
    Vesting vesting;
    Staking staking;

    address owner;
    address alice;

    function setUp() public {
        owner = address(this);           // Contract owner
        alice = vm.addr(1);              // Test user

        // Deploy contracts
        token = new MyToken();
        vesting = new Vesting(address(token));
        staking = new Staking(address(token));

        // Fund Alice with ETH for tx fees
        vm.deal(alice, 1 ether);

        // Transfer tokens to Vesting contract to distribute later
        uint256 initialSupply = 500_000 * 10 ** token.decimals();
        token.mint(address(vesting), initialSupply);

        // Transfer tokens to Staking contract for staking operations
        uint256 stakingAmount = 500_000 * 10 ** token.decimals();
        token.mint(address(staking), stakingAmount);

        // Add vesting schedule for Alice
        vesting.addVesting(
            alice,
            100_000 * 1e18 ,     // total vesting amount
            30 days,           // cliff
            90 days            // total vesting duration
        );
    }

    function testVestingToStakingFlow() public {
        // Simulate time passing to go beyond cliff
        vm.warp(block.timestamp + 45 days); // after cliff, partially vested

        // Alice claims vested tokens (e.g. ~50k if halfway)
        vm.prank(alice);
        vesting.claimTokens(50_000 * 1e18);

        uint256 aliceTokenBalance = token.balanceOf(alice);
        assertGt(aliceTokenBalance, 0, "Alice should have received vested tokens");

        // Alice approves staking contract
        vm.prank(alice);
        token.approve(address(staking), aliceTokenBalance);

        // Alice stakes the vested tokens
        vm.prank(alice);
        staking.stake(aliceTokenBalance);

        assertEq(token.balanceOf(alice), 0, "All vested tokens should be staked");

        // Fast forward time to accumulate rewards
        vm.warp(block.timestamp + 10 days);

        // Alice claims rewards
        vm.prank(alice);
        staking.claimReward();

        uint256 rewardBalance = token.balanceOf(alice);
        assertGt(rewardBalance, 0, "Alice should have received staking rewards");

        // Alice unstakes some tokens
        vm.prank(alice);
        staking.withdraw(50_000 * 1e18);

        uint256 finalBalance = token.balanceOf(alice);
        assertGt(finalBalance, 0, "Alice should have unstaked tokens + rewards");

    }
}
