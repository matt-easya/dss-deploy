// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface DsrManagerLike {
    function pieOf(address) external view returns (uint256);
    function pot() external view returns (address);
    function daiJoin() external view returns (address);
}

interface PotLike {
    function pie(address) external view returns (uint256);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function live() external view returns (uint256);
}

interface DaiJoinLike {
    function live() external view returns (uint256);
    function vat() external view returns (address);
}

interface VatLike {
    function dai(address) external view returns (uint256);
    function live() external view returns (uint256);
}

contract DiagnoseExitAll is Script {
    function run() external {
        address dsrManager = vm.envAddress("DSR_MANAGER");
        address eoa = vm.envAddress("EOA");
        address potAddr = vm.envAddress("POT");
        
        vm.createSelectFork(vm.envString("RPC"));
        
        console.log("=== DSR Manager ExitAll Diagnosis ===");
        console.log("DSR Manager:", dsrManager);
        console.log("EOA:", eoa);
        console.log("Pot:", potAddr);
        console.log("");
        
        DsrManagerLike dsr = DsrManagerLike(dsrManager);
        PotLike pot = PotLike(potAddr);
        DaiJoinLike daiJoin = DaiJoinLike(dsr.daiJoin());
        VatLike vat = VatLike(daiJoin.vat());
        
        // Check DSR Manager state
        uint256 pieOfEoa = dsr.pieOf(eoa);
        console.log("EOA pieOf balance:", pieOfEoa);
        
        if (pieOfEoa == 0) {
            console.log("ERROR: EOA has no DSR balance (pieOf = 0)");
            console.log("This is why exitAll is reverting - there's nothing to exit");
            return;
        }
        
        // Check Pot state
        console.log("Pot pie balance for DSR Manager:", pot.pie(dsrManager));
        console.log("Pot chi (rate accumulator):", pot.chi());
        console.log("Pot rho (last drip time):", pot.rho());
        console.log("Current block timestamp:", block.timestamp);
        console.log("Pot live status:", pot.live());
        
        if (pot.live() == 0) {
            console.log("ERROR: Pot is not live (caged)");
            return;
        }
        
        // Check if drip is needed
        if (block.timestamp > pot.rho()) {
            console.log("WARNING: Pot needs to be dripped (block.timestamp > rho)");
            console.log("This might cause issues with exitAll");
        }
        
        // Check DaiJoin state
        console.log("DaiJoin live status:", daiJoin.live());
        
        if (daiJoin.live() == 0) {
            console.log("ERROR: DaiJoin is not live (caged)");
            return;
        }
        
        // Check Vat state
        console.log("Vat live status:", vat.live());
        
        if (vat.live() == 0) {
            console.log("ERROR: Vat is not live (caged)");
            return;
        }
        
        uint256 vatDai = vat.dai(dsrManager);
        console.log("Vat DAI balance for DSR Manager:", vatDai);
        
        // Calculate expected DAI amount
        uint256 expectedDai = (pieOfEoa * pot.chi()) / 1e27;
        console.log("Expected DAI amount to exit:", expectedDai);
        
        // Check if there's enough DAI in vat
        if (vatDai < expectedDai) {
            console.log("ERROR: Insufficient DAI in vat for DSR Manager");
            console.log("Required:", expectedDai);
            console.log("Available:", vatDai);
            return;
        }
        
        console.log("");
        console.log("All checks passed - exitAll should work");
        console.log("If it's still reverting, try calling pot.drip() first:");
        console.log("cast send", potAddr, "drip() --rpc-url $RPC --private-key $PRIVATE_KEY");
    }
}
