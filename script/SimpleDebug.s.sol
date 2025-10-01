// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract SimpleDebug is Script {
    function run() external view {
        console.log("=== SIMPLE DEBUG TEST ===\n");

        // Your actual data from the log
        bytes memory actualData = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0e77d2bd163c1d1e0f6d02bd9b28f5b1b0efd4ecd39aa2db3cc6d3d720b6495a2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000405852502d410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000";
        
        console.log("Data length:", actualData.length);
        console.log("Data hex:", vm.toString(actualData));
        console.log("");

        // Test 1: Try to decode as bytes
        console.log("=== TEST 1: Decode as (bytes) ===");
        bytes memory decodedBytes = abi.decode(actualData, (bytes));
        console.log("SUCCESS! Decoded bytes length:", decodedBytes.length);
        console.log("Decoded bytes hex:", vm.toString(decodedBytes));
        console.log("");

        // Test 2: Try to decode the inner bytes as (bytes32, bytes)
        console.log("=== TEST 2: Decode inner as (bytes32, bytes) ===");
        (bytes32 op, bytes memory params) = abi.decode(decodedBytes, (bytes32, bytes));
        console.log("SUCCESS! Operation:", vm.toString(op));
        console.log("Params length:", params.length);
        console.log("Params hex:", vm.toString(params));
        console.log("");

        // Test 3: Check if operation matches expected
        bytes32 OP_DEPOSIT_AND_SWAP = keccak256("deposit_and_swap");
        console.log("=== TEST 3: Operation Check ===");
        console.log("Expected OP_DEPOSIT_AND_SWAP:", vm.toString(OP_DEPOSIT_AND_SWAP));
        console.log("Actual operation:", vm.toString(op));
        console.log("Match?", op == OP_DEPOSIT_AND_SWAP);
        console.log("");

        // Test 4: Decode params
        console.log("=== TEST 4: Decode Params ===");
        (bytes32 ilk, uint256 daiToDraw) = abi.decode(params, (bytes32, uint256));
        console.log("Ilk:", vm.toString(ilk));
        console.log("DaiToDraw:", daiToDraw);
        console.log("DaiToDraw = 1 ether?", daiToDraw == 1 ether);
    }
}
