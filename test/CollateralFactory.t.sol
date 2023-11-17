// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/CollateralFactory.sol";
import "../src/OSMFactory.sol";
import "../src/JoinFactory.sol";
import "../src/AuctionHouseFactory.sol";
import {KeeperIncentivesFactory} from "./KeeperIncentivesMock.sol";

library GetCode {
    function at(address _addr) public view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(
                0x40,
                add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly on the old compiler version
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}

abstract contract AuthLike {
    function authorizedAccounts(address) external view virtual returns (uint);
}

abstract contract SafeEngineLike is AuthLike {
    function collateralTypes(
        bytes32
    ) external view virtual returns (uint, uint, uint, uint, uint, uint);
}

abstract contract LiquidationEngineLike is AuthLike {
    function collateralAuctionHouse() external view virtual returns (address);

    function liquidationPenalty() external view virtual returns (uint);

    function liquidationQuantity() external view virtual returns (uint);

    function collateralTypes(
        bytes32
    ) external view virtual returns (address, uint, uint);
}

abstract contract OracleRelayerLike is AuthLike {
    function collateralTypes(
        bytes32
    ) external view virtual returns (address, uint, uint);
}

abstract contract GlobalSettlementLike is AuthLike {}

abstract contract TaxCollectorLike is AuthLike {
    function collateralTypes(
        bytes32
    ) external view virtual returns (uint, uint);
}

abstract contract AuctionHouseLike is AuthLike {
    function safeEngine() external view virtual returns (address);

    function liquidationEngine() external view virtual returns (address);

    function collateralType() external view virtual returns (bytes32);

    function oracleRelayer() external view virtual returns (address);

    function collateralFSM() external view virtual returns (address);

    function minimumBid() external view virtual returns (uint);

    function perSecondDiscountUpdateRate() external view virtual returns (uint);

    function minDiscount() external view virtual returns (uint);

    function maxDiscount() external view virtual returns (uint);

    function maxDiscountUpdateRateTimeline()
        external
        view
        virtual
        returns (uint);

    function lowerCollateralMedianDeviation()
        external
        view
        virtual
        returns (uint);

    function upperCollateralMedianDeviation()
        external
        view
        virtual
        returns (uint);
}

abstract contract JoinLike is AuthLike {
    function safeEngine() external view virtual returns (address);

    function collateral() external view virtual returns (address);

    function collateralType() external view virtual returns (bytes32);
}

abstract contract OSMLike is AuthLike {
    function priceSource() external view virtual returns (address);
}

abstract contract KeeperIncentivesLike is AuthLike {
    function treasury() external view virtual returns (address);

    function osm() external view virtual returns (address);

    function oracleRelayer() external view virtual returns (address);

    function coinOracle() external view virtual returns (address);

    function ethOracle() external view virtual returns (address);
}

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(
        address
    ) external view virtual returns (uint256, uint256);
}

contract CollateralFactoryTest is Test {
    CollateralFactory public factory;
    SafeEngineLike public safeEngine =
        SafeEngineLike(0x3AD2F30266B35F775D58Aecde3fbB7ea8b83bF2b);
    LiquidationEngineLike public liquidationEngine =
        LiquidationEngineLike(0x6557765796c3b86A721B527006765D056eC038b9);
    OracleRelayerLike public oracleRelayer =
        OracleRelayerLike(0x6aa9D2f366beaAEc40c3409E5926e831Ea42DC82);
    GlobalSettlementLike public globalSettlement =
        GlobalSettlementLike(0xeCa7B1F7e98B4ff65002DA43206fD2bE2d3aD0A3);
    TaxCollectorLike public taxCollector =
        TaxCollectorLike(0x3578743e922941911638a01521947ef1a81E0878);
    StabilityFeeTreasuryLike public stabilityFeeTreasury =
        StabilityFeeTreasuryLike(0xB3c5866f6690AbD50536683994Cc949697a64cd0);
    address public pauseProxy = 0xaDEA80Db702690A80cd123BA7ddCF6F541884E4f;

    function setUp() public {
        address osmFactory = address(new OSMFactory());
        address joinFactory = address(new JoinFactory());
        address auctionHouseFactory = address(new AuctionHouseFactory());
        address keeperIncentivesFactory = address(
            new KeeperIncentivesFactory()
        );

        // mainnet
        factory = new CollateralFactory(
            pauseProxy,
            address(safeEngine),
            address(liquidationEngine),
            address(oracleRelayer),
            address(globalSettlement),
            address(taxCollector),
            address(stabilityFeeTreasury),
            osmFactory,
            joinFactory,
            auctionHouseFactory,
            keeperIncentivesFactory
        );

        vm.etch(pauseProxy, GetCode.at(address(factory)));
        factory = CollateralFactory(pauseProxy);
    }

    function testDeployCollateralSpecificContracts() public {
        address token = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0; // mainnet WSTETH
        address priceFeed = 0xd0B49e3d0313bb3Cad456B62A99A0BcB366FB6a2; // COLLATERAL_ORACLE_WSTETH
        address coinOracle = 0xC8078539f56ae8E0e3741BAa8F8Ed939D63976a8; // SYSTEM_COIN_ORACLE
        address ethOracle = 0x4EdbE53a846087075291fB575e8fFb4b00B1c5E4; // COLLATERAL_ORACLE_ETH
        (
            address joinAddress,
            address auctionHouseAddress,
            address osmAddress,
            address keeperIncentivesAddress
        ) = factory.deployCollateralSpecificContracts(
                "WSTETH-X",
                token,
                priceFeed,
                coinOracle,
                ethOracle,
                50 // 5% deviation
            );

        JoinLike join = JoinLike(joinAddress);
        assertEq(join.safeEngine(), address(safeEngine));
        assertEq(join.collateralType(), bytes32("WSTETH-X"));
        assertEq(join.collateral(), address(token));
        assertEq(join.authorizedAccounts(address(this)), 0);
        assertEq(join.authorizedAccounts(address(pauseProxy)), 1);

        AuctionHouseLike auctionHouse = AuctionHouseLike(auctionHouseAddress);
        assertEq(auctionHouse.safeEngine(), address(safeEngine));
        assertEq(auctionHouse.liquidationEngine(), address(liquidationEngine));
        assertEq(auctionHouse.collateralType(), bytes32("WSTETH-X"));
        assertEq(auctionHouse.authorizedAccounts(address(this)), 0);
        assertEq(auctionHouse.authorizedAccounts(address(pauseProxy)), 1);

        OSMLike osm = OSMLike(osmAddress);
        assertEq(osm.priceSource(), priceFeed);
        assertEq(osm.authorizedAccounts(address(this)), 0);
        assertEq(osm.authorizedAccounts(address(pauseProxy)), 1);

        KeeperIncentivesLike incentives = KeeperIncentivesLike(
            keeperIncentivesAddress
        );
        assertEq(incentives.treasury(), address(stabilityFeeTreasury));
        assertEq(incentives.osm(), address(osm));
        assertEq(incentives.oracleRelayer(), address(oracleRelayer));
        assertEq(incentives.coinOracle(), address(coinOracle));
        assertEq(incentives.ethOracle(), address(ethOracle));
        assertEq(incentives.authorizedAccounts(address(this)), 0);
        assertEq(incentives.authorizedAccounts(address(pauseProxy)), 1);
    }

    function testDeployCollateralType() public {
        address token = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0; // mainnet WSTETH
        address priceFeed = 0xd0B49e3d0313bb3Cad456B62A99A0BcB366FB6a2; // COLLATERAL_ORACLE_WSTETH
        address coinOracle = 0xC8078539f56ae8E0e3741BAa8F8Ed939D63976a8; // SYSTEM_COIN_ORACLE
        address ethOracle = 0x4EdbE53a846087075291fB575e8fFb4b00B1c5E4; // COLLATERAL_ORACLE_ETH
        (
            address joinAddress,
            address auctionHouseAddress,
            address osmAddress,
            address keeperIncentivesAddress
        ) = factory.deployCollateralSpecificContracts(
                "WSTETH-X",
                token,
                priceFeed,
                coinOracle,
                ethOracle,
                50 // 5% deviation
            );

        factory.deployCollateralType(
            joinAddress,
            osmAddress,
            auctionHouseAddress,
            keeperIncentivesAddress,
            195 * 10 ** 25,
            10000000 * 10 ** 45,
            15000 * 10 ** 45,
            1000000000705562181084137269, // 2.25%
            1.02e18
        );

        JoinLike join = JoinLike(joinAddress);
        AuctionHouseLike auctionHouse = AuctionHouseLike(auctionHouseAddress);

        assertEq(join.authorizedAccounts(pauseProxy), 1);
        assertEq(auctionHouse.authorizedAccounts(pauseProxy), 1);

        assertEq(join.safeEngine(), address(safeEngine));
        assertEq(join.collateralType(), bytes32("WSTETH-X"));
        assertEq(join.collateral(), address(token));

        assertEq(safeEngine.authorizedAccounts(address(join)), 1);

        assertEq(auctionHouse.safeEngine(), address(safeEngine));
        assertEq(auctionHouse.liquidationEngine(), address(liquidationEngine));
        assertEq(auctionHouse.collateralType(), bytes32("WSTETH-X"));
        {
            (
                address auctionHouse_,
                uint liquidationPenalty,
                uint liquidationQuantity
            ) = liquidationEngine.collateralTypes("WSTETH-X");
            assertEq(auctionHouse_, address(auctionHouse));
            assertEq(liquidationPenalty, 1.02e18);
            assertEq(liquidationQuantity, 90000 * 10 ** 45);
        }

        assertEq(
            liquidationEngine.authorizedAccounts(address(auctionHouse)),
            1
        );
        assertEq(
            auctionHouse.authorizedAccounts(address(liquidationEngine)),
            1
        );
        assertEq(auctionHouse.authorizedAccounts(address(globalSettlement)), 1);

        {
            (
                address orcl,
                uint safetyCRatio,
                uint liquidationCRatio
            ) = oracleRelayer.collateralTypes("WSTETH-X");
            assertEq(orcl, address(osmAddress));
            assertEq(safetyCRatio, 195 * 10 ** 25);
            assertEq(liquidationCRatio, 195 * 10 ** 25);
        }

        {
            (
                uint debtAmount,
                uint accumulatedRate,
                uint safetyPrice,
                uint debtCeiling,
                uint debtFloor,
                uint liquidationPrice
            ) = safeEngine.collateralTypes("WSTETH-X");
            assertEq(debtAmount, 0);
            assertEq(accumulatedRate, 10 ** 27);
            assertEq(debtCeiling, 10000000 * 10 ** 45);
            assertEq(debtFloor, 15000 * 10 ** 45);
            assertGt(safetyPrice, 0);
            assertGt(liquidationPrice, 0);
        }

        (uint stabilityFee, uint updateTime) = taxCollector.collateralTypes(
            "WSTETH-X"
        );
        assertEq(stabilityFee, 1000000000705562181084137269);
        assertEq(updateTime, now);

        assertEq(auctionHouse.oracleRelayer(), address(oracleRelayer));
        assertEq(auctionHouse.collateralFSM(), osmAddress);
        assertEq(auctionHouse.minimumBid(), 0);
        assertEq(
            auctionHouse.perSecondDiscountUpdateRate(),
            999999410259856537771597932
        );
        assertEq(auctionHouse.minDiscount(), 0.99E18);
        assertEq(auctionHouse.maxDiscount(), 0.70E18);
        assertEq(auctionHouse.maxDiscountUpdateRateTimeline(), 7 days);
        assertEq(auctionHouse.lowerCollateralMedianDeviation(), 0.70E18);
        assertEq(auctionHouse.upperCollateralMedianDeviation(), 0.90E18);

        (uint total, uint perBlock) = stabilityFeeTreasury.getAllowance(
            keeperIncentivesAddress
        );
        assertEq(total, uint(-1));
        assertEq(perBlock, 100 * 10 ** 18);
    }
}
