pragma solidity 0.6.7;

import {OSM} from "geb-fsm/OSM.sol";

contract OSMFactory {
    function deploy(address priceSource_, address owner) external returns (address) {
        OSM osm = new OSM(priceSource_);
        osm.addAuthorization(owner);
        osm.removeAuthorization(address(this));            
        return address(osm);
    }
}
