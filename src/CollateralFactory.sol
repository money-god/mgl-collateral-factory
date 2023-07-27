// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity 0.6.7;

abstract contract FactoryLike {
    function deploy(address, bytes32, address) external virtual returns (address);

    function deploy(address) external virtual returns (address);

    function deploy(address, address, bytes32) external virtual returns (address);
}

abstract contract Setter {
    function addAuthorization(address) external virtual;

    function modifyParameters(bytes32, address) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function modifyParameters(bytes32, bytes32, address) external virtual;

    function modifyParameters(bytes32, bytes32, uint256) external virtual;

    function initializeCollateralType(bytes32) external virtual;

    function updateCollateralPrice(bytes32) external virtual;
}

// @dev This is just a proxy action, meant to be used by a GEB system and called through DS-Pause (it assumes the caller, DS-Proxy, owns all contracts it touches)
// @dev Direct calls to this contract will revert.
contract CollateralFactory {
    Setter immutable safeEngine;
    Setter immutable taxCollector;
    Setter immutable liquidationEngine;
    Setter immutable oracleRelayer;
    Setter immutable globalSettlement;
    FactoryLike immutable joinFactory;
    FactoryLike immutable auctionHouseFactory;

    constructor(
        address safeEngine_,
        address liquidationEngine_,
        address oracleRelayer_,
        address globalSettlement_,
        address taxCollector_,
        address joinFactory_,
        address auctionHouseFactory_
    ) public {
        safeEngine = Setter(safeEngine_);
        liquidationEngine = Setter(liquidationEngine_);
        oracleRelayer = Setter(oracleRelayer_);
        globalSettlement = Setter(globalSettlement_);
        taxCollector = Setter(taxCollector_);
        joinFactory = FactoryLike(joinFactory_);
        auctionHouseFactory = FactoryLike(auctionHouseFactory_);
    }

    function deployCollateralType(
        address token,
        address osm,
        bytes32 collateralType,
        uint256 cRatio,
        uint256 debtCeiling,
        uint256 debtFloor,
        uint256 stabilityFee,
        uint256 liquidationPenalty
    ) public  returns (address, address) {
        Setter join = Setter(
            joinFactory.deploy(address(safeEngine), collateralType, token)
        );

        safeEngine.addAuthorization(address(join));

        Setter auctionHouse = Setter(
            auctionHouseFactory.deploy(
                address(safeEngine),
                address(liquidationEngine),
                collateralType
            )
        );

        liquidationEngine.modifyParameters(
            collateralType,
            "collateralAuctionHouse",
            address(auctionHouse)
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationPenalty",
            liquidationPenalty
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationQuantity",
            90000 * 10 ** 45
        );

        liquidationEngine.addAuthorization(address(auctionHouse));
        auctionHouse.addAuthorization(address(liquidationEngine));
        auctionHouse.addAuthorization(address(globalSettlement));

        oracleRelayer.modifyParameters(collateralType, "orcl", osm);
        oracleRelayer.modifyParameters(
            collateralType,
            "safetyCRatio",
            cRatio
        );
        oracleRelayer.modifyParameters(
            collateralType,
            "liquidationCRatio",
            cRatio
        );        

        safeEngine.initializeCollateralType(collateralType);
        safeEngine.modifyParameters(
            collateralType,
            "debtCeiling",
            debtCeiling
        );
        safeEngine.modifyParameters(collateralType, "debtFloor", debtFloor);        

        taxCollector.initializeCollateralType(collateralType);
        taxCollector.modifyParameters(
            collateralType,
            "stabilityFee",
            stabilityFee
        );

        auctionHouse.modifyParameters("oracleRelayer", address(oracleRelayer));
        auctionHouse.modifyParameters("collateralFSM", osm);
        auctionHouse.modifyParameters("minimumBid", 0);
        auctionHouse.modifyParameters("perSecondDiscountUpdateRate", 999999410259856537771597932);
        auctionHouse.modifyParameters("minDiscount", 0.99E18);
        auctionHouse.modifyParameters("maxDiscount", 0.70E18);
        auctionHouse.modifyParameters("maxDiscountUpdateRateTimeline", 7 days);
        auctionHouse.modifyParameters(
            "lowerCollateralMedianDeviation",
            0.70E18
        );
        auctionHouse.modifyParameters(
            "upperCollateralMedianDeviation",
            0.90E18
        );

        oracleRelayer.updateCollateralPrice(collateralType);

        return (address(join), address(auctionHouse));
    }
}
