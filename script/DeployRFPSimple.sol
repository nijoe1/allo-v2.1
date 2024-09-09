// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {RFPSimple} from "contracts/strategies/examples/rfp/RFPSimple.sol";

contract DeployRFPSimple is DeployBase {
    function _deploy() internal override returns (address _contract) {
        address _allo = vm.envAddress("ALLO_ADDRESS");
        return address(new RFPSimple(_allo));
    }
}
