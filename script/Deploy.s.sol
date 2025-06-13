// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
import "../src/Vesting.sol";
import "../src/Staking.sol";

contract Deploy is Script {
    function run() external {
        uint deployerPrivateKey = vm.envUint ("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy MyToken contract
        MyToken token = new MyToken();
        console.log("MyToken deployed at:", address(token));

        // Deploy Vesting contract with token address
        Vesting vesting = new Vesting(address(token));
        console.log("Vesting deployed at:", address(vesting));

        // Deploy Staking contract with token address
        Staking staking = new Staking(address(token));
        console.log("Staking deployed at:", address(staking));

        vm.stopBroadcast();
    }
}
