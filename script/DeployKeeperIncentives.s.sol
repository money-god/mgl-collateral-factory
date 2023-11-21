// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/KeeperIncentivesFactory.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        new KeeperIncentivesFactory();


        vm.stopBroadcast();
    }
}
