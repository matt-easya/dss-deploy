// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract TestDoubleEncoding is Script {
    bytes32 constant OP_DEPOSIT_AND_SWAP = keccak256("deposit_and_swap");

    function run() external view {
        console.log("=== DOUBLE ENCODING TEST ===\n");

        // Your expected inner payload
        bytes32 testIlk = "XRP-A";
        uint256 testDaiToDraw = 1 ether;
        bytes memory testParams = abi.encode(testIlk, testDaiToDraw);
        bytes memory innerPayload = abi.encode(OP_DEPOSIT_AND_SWAP, testParams);
        
        console.log("--- Inner Payload (what you expect) ---");
        console.log("Length:", innerPayload.length);
        console.log("Hex:", vm.toString(innerPayload));
        console.log("");

        // What you're actually receiving (double encoded)
        bytes memory outerPayload = abi.encode(innerPayload);
        
        console.log("--- Outer Payload (what you're receiving) ---");
        console.log("Length:", outerPayload.length);
        console.log("Hex:", vm.toString(outerPayload));
        console.log("");

        // Your actual data from the log
        bytes memory actualData = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0e77d2bd163c1d1e0f6d02bd9b28f5b1b0efd4ecd39aa2db3cc6d3d720b6495a2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000405852502d410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000";
        
        console.log("--- Your Actual Data ---");
        console.log("Length:", actualData.length);
        console.log("Hex:", vm.toString(actualData));
        console.log("");

        // Check if they match
        console.log("--- Comparison ---");
        console.log("Outer matches actual?", keccak256(outerPayload) == keccak256(actualData));
        console.log("");

        // Now let's decode it properly
        console.log("--- Decoding Actual Data ---");
        
        // First, decode the outer wrapper to get the inner bytes
        bytes memory decodedInner = abi.decode(actualData, (bytes));
        console.log("Decoded inner length:", decodedInner.length);
        console.log("Decoded inner hex:", vm.toString(decodedInner));
        console.log("");

        // Now decode the operation and params from the inner bytes
        (bytes32 op, bytes memory params) = abi.decode(decodedInner, (bytes32, bytes));
        console.log("Operation:", vm.toString(op));
        console.log("Matches OP_DEPOSIT_AND_SWAP:", op == OP_DEPOSIT_AND_SWAP);
        console.log("Params length:", params.length);
        console.log("Params hex:", vm.toString(params));
        console.log("");

        // Decode the params
        (bytes32 ilk, uint256 daiToDraw) = abi.decode(params, (bytes32, uint256));
        console.log("Decoded params:");
        console.log("  Ilk:", vm.toString(ilk));
        console.log("  DaiToDraw:", daiToDraw);
        console.log("  DaiToDraw matches 1 ether:", daiToDraw == 1 ether);
    }
}
