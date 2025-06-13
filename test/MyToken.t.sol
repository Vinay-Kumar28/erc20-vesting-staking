// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

error OwnableUnauthorizedAccount(address account);


contract MyTokenTest is Test {

    MyToken token;
    address user1;
    address user2;
    address owner;

function setUp() public {

    token = new MyToken();
    
     user1 = address(1);
     user2 = address(2);
     owner = address(this);
}

function testInitialSupply() public view {
    uint expectedSupply = 1_000_000 * 10 ** token.decimals();
    assertEq(token.totalSupply(), expectedSupply);
    assertEq(token.balanceOf(owner), expectedSupply);
}

function testTransfer() public {

    token.transfer(user1 , 50*10**token.decimals());
    assertEq(token.balanceOf(user1), 50*10**token.decimals());
    
    }

function testTransferFromWithApproval() public {
    uint256 amount = 100 * 10 ** token.decimals();
    uint256 transferAmount = 50 * 10 ** token.decimals();

    // owner (this contract) approves user1
    token.approve(user1, amount);

    // 👇 Check the allowance before transferFrom
    assertEq(token.allowance(address(this), user1), amount);

    // user1 tries to transfer
    vm.prank(user1);
    token.transferFrom(address(this), user2, transferAmount);

    assertEq(token.balanceOf(user2), transferAmount);
    assertEq(token.allowance(address(this), user1), amount - transferAmount);
}



function testOnlyOwnerCanTransferOwnership() public {
    vm.prank(user1);
    vm.expectRevert(
        abi.encodeWithSelector(
            OwnableUnauthorizedAccount.selector,
            user1
        )
    );
    token.transferOwnership(user2);
}


}