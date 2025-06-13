// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Vesting.sol";
import "../src/MyToken.sol";

contract VestingTest is Test {
    MyToken token;
    Vesting vesting;
    address owner = address(1);
    address beneficiary = address(2);
    uint initialSupply = 1_000_000 * 1e18;

    function setUp() public {
        // Deploy token and vesting contract as `owner`
        vm.startPrank(owner);
        token = new MyToken();
        vesting = new Vesting(address(token));
        token.transfer(address(vesting), 500_000 * 1e18);
        vm.stopPrank();
    }

    function testAddVestingAndCliffRevert() public {
        vm.startPrank(owner);
        uint cliff = 30 days;
        uint duration = 90 days;
        uint amount = 90_000 * 1e18;
        vesting.addVesting(beneficiary, amount, cliff, duration);
        vm.stopPrank();

        vm.startPrank(beneficiary);
        vm.expectRevert("Cliff not reached");
        vesting.claimTokens(1 * 1e18);
        vm.stopPrank();
    }

    function testClaimAfterCliffAndLinearRelease() public {
        vm.startPrank(owner);
        uint cliff = 30 days;
        uint duration = 90 days;
        uint amount = 90_000 * 1e18;
        vesting.addVesting(beneficiary, amount, cliff, duration);
        vm.stopPrank();

        // advance time to 45 days(15 days after cliff)
        vm.warp(block.timestamp + 45 days);

        vm.startPrank(beneficiary);
        uint expectedVested = amount * 45 days / duration;
        uint claimable = vesting.getClaimableTokens();
        assertEq(claimable, expectedVested);

        // claim half
        uint toClaim = expectedVested / 2;
        vesting.claimTokens(toClaim);
        assertEq(token.balanceOf(beneficiary), toClaim);

        // check updated claimable
        uint newClaimable = vesting.getClaimableTokens();
        assertEq(newClaimable, expectedVested - toClaim);
        vm.stopPrank();
    }

    function testFullClaimAfterDuration() public {
        vm.startPrank(owner);
        uint cliff = 10 days;
        uint duration = 60 days;
        uint amount = 60_000 * 1e18;
        vesting.addVesting(beneficiary, amount, cliff, duration);
        vm.stopPrank();

        vm.warp(block.timestamp + 90 days); // after full duration

        vm.startPrank(beneficiary);
        uint claimable = vesting.getClaimableTokens();
        assertEq(claimable, amount);

        vesting.claimTokens(amount);
        assertEq(token.balanceOf(beneficiary), amount);
        vm.stopPrank();
    }

    function testDoubleClaimReverts() public {
        vm.startPrank(owner);
        uint cliff = 5 days;
        uint duration = 10 days;
        uint amount = 10_000 * 1e18;
        vesting.addVesting(beneficiary, amount, cliff, duration);
        vm.stopPrank();

        vm.warp(block.timestamp + 11 days); // Fully vested

        vm.startPrank(beneficiary);
        vesting.claimTokens(amount);

        // Try to claim again (should fail)
        vm.expectRevert("Not enough vested tokens");
        vesting.claimTokens(1 * 1e18);
        vm.stopPrank();
    }
}

