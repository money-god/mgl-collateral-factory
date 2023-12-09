// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "forge-std/Script.sol";
import {OSM} from "geb-fsm/OSM.sol";
import "../src/JoinFactory.sol";
import "../src/AuctionHouseFactory.sol";
import "../src/CollateralFactory.sol";
import "../src/OSMFactory.sol";
// import "../src/KeeperIncentivesFactory.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address joinFactory = 0x6b8cDDc434272E0b0F295913B5A8CCD199ac491F;
        address auctionHouseFactory = 0x4A3f50Ee31318bE0234e13244Da413df615901e3;
        address osmFactory = 0xebb80c260b74F8389536c5514f6F06794A4935B2;
        address keeperIncentivesFactory = 0x295D6C315eAb2E23F37b5808c7b1a4a381285db0; 


        // mainnet
        new CollateralFactory(
            0xaDEA80Db702690A80cd123BA7ddCF6F541884E4f, // pause proxy
            0x3AD2F30266B35F775D58Aecde3fbB7ea8b83bF2b, // safeEngine
            0x6557765796c3b86A721B527006765D056eC038b9, // liquidationEngine
            0x6aa9D2f366beaAEc40c3409E5926e831Ea42DC82, // oracleRelayer
            0xeCa7B1F7e98B4ff65002DA43206fD2bE2d3aD0A3, // globalSettlement
            0x3578743e922941911638a01521947ef1a81E0878, // taxCollector       
            0xB3c5866f6690AbD50536683994Cc949697a64cd0, // stability fee treasury
            osmFactory,
            joinFactory,
            auctionHouseFactory,
            keeperIncentivesFactory
        );

        vm.stopBroadcast();
    }
}
