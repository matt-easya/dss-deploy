// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy} from "src/DssDeploy.sol";
import {DsrManager} from "src/DsrManager.sol";

interface PotLike {
    function drip() external returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function dsr() external view returns (uint256);
    function rho() external view returns (uint256);
    function rely(address guy) external;
    function join(uint256 wad) external;
    function exit(uint256 wad) external;
}

interface DsrManagerLike {
    function dripAndFile(address pot, bytes32 what, uint256 data) external;
    function dripAndJoin(address pot, uint256 wad) external;
    function dripAndExit(address pot, uint256 wad) external;
}



// Using DsrManager from sky-ecosystem/dsr-manager
// This is a specialized contract for DSR operations that handles
// atomic drip() + file() operations properly


// Simple wrapper to handle atomic drip + file operations
contract PotInitializer {
    function dripAndFile(address pot, bytes32 what, uint256 data) external {
        PotLike(pot).drip();
        PotLike(pot).file(what, data);
    }
}

contract InitPot is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        
        // DSR rate (in ray, per-second accumulation)
        // Default to 1% annual rate (per-second): ~1.000000000315522921573372069
        uint256 dsrRate = vm.envOr("DSR_RATE", uint256(1000000000315522921573372069)); // 1% annual
        
        vm.startBroadcast();

        // Get core addresses from DssDeploy
        DssDeploy deploy = DssDeploy(dssDeployAddr);
        address potAddr = address(deploy.pot());
        
        PotLike pot = PotLike(potAddr);
        
        console2.log("Initializing Pot at:", potAddr);
        console2.log("Current DSR:", pot.dsr());
        console2.log("Current rho:", pot.rho());
        console2.log("Block timestamp:", block.timestamp);
        
        // Deploy the DsrManager contract
        address daiJoin = address(deploy.daiJoin());
        DsrManager dsrManagerContract = new DsrManager(potAddr, daiJoin);
        DsrManagerLike dsrManager = DsrManagerLike(address(dsrManagerContract));
        console2.log("Deployed DsrManager at:", address(dsrManagerContract));
        console2.log("  Pot:", potAddr);
        console2.log("  DaiJoin:", daiJoin);
        
        // Deploy PotInitializer for atomic drip + file operations
        PotInitializer potInitializer = new PotInitializer();
        console2.log("Deployed PotInitializer at:", address(potInitializer));
        
        // Authorize the PotInitializer to call file() on the pot
        console2.log("Authorizing PotInitializer to call file()...");
        pot.rely(address(potInitializer));
        
        // Call dripAndFile atomically
        console2.log("Calling dripAndFile with DSR:", dsrRate);
        potInitializer.dripAndFile(potAddr, "dsr", dsrRate);
        
        console2.log("Pot initialization complete!");
        console2.log("Final DSR:", pot.dsr());
        console2.log("Final rho:", pot.rho());
        console2.log("DSR_MANAGER=", address(dsrManagerContract));

        vm.stopBroadcast();
    }
}