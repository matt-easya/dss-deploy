// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy} from "src/DssDeploy.sol";
import {DssCdpManager} from "dss-cdp-manager/DssCdpManager.sol";

contract DeployCDPManager is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        
        vm.startBroadcast();

        // Get core addresses from DssDeploy
        DssDeploy deploy = DssDeploy(dssDeployAddr);
        address vat = address(deploy.vat());

        // Deploy the CDP Manager
        DssCdpManager cdpManager = new DssCdpManager(vat);

        // Log addresses for .envrc
        console2.log("CDP_MANAGER=", address(cdpManager));
        console2.log("VAT=", vat);

        vm.stopBroadcast();
    }
}
