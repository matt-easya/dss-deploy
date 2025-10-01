// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract SimpleCalldata is Script {
    function run() external view {
        // Operation constant
        bytes32 OP_DEPOSIT_AND_SWAP = keccak256("deposit_and_swap");
        
        // Parameters
        bytes32 ilk = "XRP-A"; // Encode directly as bytes32
        uint256 daiToDraw = 1 * 10**18; // 1 DAI
        
        console.log("Operation:", vm.toString(OP_DEPOSIT_AND_SWAP));
        console.log("ILK:", vm.toString(ilk));
        console.log("DaiToDraw:", daiToDraw);
        console.log("");
        
        // Encode parameters
        bytes memory params = abi.encode(ilk, daiToDraw);
        console.log("Params length:", params.length);
        console.log("Params:");
        console.logBytes(params);
        console.log("");
        
        // Encode complete data payload (what you send)
        bytes memory data = abi.encode(OP_DEPOSIT_AND_SWAP, params);
        console.log("Data length:", data.length);
        console.log("Data payload (what you're sending):");
        console.logBytes(data);
        console.log("");
        
        // What the Controller receives (double-encoded)
        bytes memory doubleEncoded = abi.encode(data);
        console.log("Double-encoded length:", doubleEncoded.length);
        console.log("Double-encoded (what Controller receives):");
        console.logBytes(doubleEncoded);
    }
}
