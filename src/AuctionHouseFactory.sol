pragma solidity 0.6.7;

import {IncreasingDiscountCollateralAuctionHouse} from "geb/single/CollateralAuctionHouse.sol";

contract AuctionHouseFactory {
    function deploy(
        address safeEngine,
        address liquidationEngine,
        bytes32 collateralType
    ) external returns (address) {
        IncreasingDiscountCollateralAuctionHouse auctionHouse = new IncreasingDiscountCollateralAuctionHouse(
                safeEngine,
                liquidationEngine,
                collateralType
            );
        auctionHouse.addAuthorization(msg.sender);
        auctionHouse.removeAuthorization(address(this));
        return address(auctionHouse);
    }
}
