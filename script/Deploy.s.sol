// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "forge-std/Script.sol";
import {OSM} from "geb-fsm/OSM.sol";
import "../src/JoinFactory.sol";
import "../src/AuctionHouseFactory.sol";
import "../src/CollateralFactory.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address joinFactory = address(new JoinFactory());
        address auctionHouseFactory = address(new AuctionHouseFactory());

        // goerli
        new CollateralFactory(
            0x39b2bfeE7cD3329F213ec1ce464f415EFe743D4b, // safeEngine
            0xaDDa40bDE5413904fa3c4280Aa06bc42D2282f8B, // liquidationEngine
            0x14f4ba19E4fDA58BFa30C11d0390C6027C155d5F, // oracleRelayer
            0x075B28fC5C90A3a2F7dCa5bDCe15Fd7749bb4791, // globalSettlement
            0xB0581eee3864236F8F481042616460f0D3B23a08, // taxCollector            
            joinFactory,
            auctionHouseFactory
        );

        vm.stopBroadcast();
    }
}
