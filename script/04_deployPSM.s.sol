// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy} from "src/DssDeploy.sol";
import {DssPsm} from "dss-psm/psm.sol";

interface PsmLike {
    function file(bytes32, uint256) external;
    function rely(address) external;
    function deny(address) external;
}

interface GemJoinLike {
    function rely(address) external;
}

interface VatLike {
    function hope(address) external;
}

contract DeployPSM is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        address GEM_JOIN_USDC = vm.envAddress("USDC_JOIN");
        
        // PSM fee parameters (in wad, 1e18 = 100%)
        uint256 tin = 0; // 0% fee for USDC→DAI (typical for PSM)
        uint256 tout = 0; // 0% fee for DAI→USDC (typical for PSM)

        vm.startBroadcast();

        // Get core addresses from DssDeploy
        DssDeploy deploy = DssDeploy(dssDeployAddr);
        address DAI_JOIN = address(deploy.daiJoin());
        address VOW = address(deploy.vow());

        // 4) Deploy the PSM contract
        DssPsm psm = new DssPsm(
            GEM_JOIN_USDC,
            DAI_JOIN,
            VOW
        );

        // 5) Give permissions
        // Allow PSM to join/exit USDC
        GemJoinLike(GEM_JOIN_USDC).rely(address(psm));
        
        // Give governance control
        VatLike(address(deploy.vat())).hope(address(psm));
        // Remove deployer permissions for safety

        // 6) Configure PSM fees
        PsmLike(address(psm)).file("tin", tin);
        PsmLike(address(psm)).file("tout", tout);

        // Log addresses for .envrc
        console2.log("PSM=", address(psm));
        console2.log("DAI_JOIN=", DAI_JOIN);
        console2.log("VOW=", VOW);

        vm.stopBroadcast();
    }
}
