pragma solidity 0.8.19;

import {BasefeeOSMDeviationCallBundler} from "mgl-keeper-incentives/Callers/BasefeeOSMDeviationCallBundler.sol";

contract KeeperIncentivesFactory {
    function deploy(
        address treasury_,
        address osm_,
        address oracleRelayer_,
        bytes32[3] memory collateral_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_,
        address owner
    ) external returns (address) {
        BasefeeOSMDeviationCallBundler bundler = new BasefeeOSMDeviationCallBundler(
                treasury_,
                osm_,
                oracleRelayer_,
                collateral_,
                reward_,
                delay_,
                coinOracle_,
                ethOracle_
            );
        bundler.addAuthorization(owner);
        bundler.removeAuthorization(address(this));            
        return address(bundler);
    }
}
