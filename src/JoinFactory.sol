pragma solidity 0.6.7;

import {BasicCollateralJoin} from "geb/shared/BasicTokenAdapters.sol";

contract JoinFactory {
    function deploy(
        address safeEngine,
        bytes32 collateralType,
        address collateralAddress
    ) external returns (address) {
        BasicCollateralJoin join = new BasicCollateralJoin(
            safeEngine,
            collateralType,
            collateralAddress
        );
        join.addAuthorization(msg.sender);
        join.removeAuthorization(address(this));
        return address(join);
    }
}
