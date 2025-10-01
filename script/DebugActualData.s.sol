// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract DebugActualData is Script {
    function run() external view {
        console.log("=== COMPREHENSIVE DATA DEBUG ===\n");

        // Your actual data from the log
        bytes memory actualData = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0e77d2bd163c1d1e0f6d02bd9b28f5b1b0efd4ecd39aa2db3cc6d3d720b6495a2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000405852502d410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000";
        
        console.log("=== RAW DATA ANALYSIS ===");
        console.log("Data length:", actualData.length);
        console.log("Data hex:", vm.toString(actualData));
        console.log("");

        // Test 1: Try to decode as just bytes (what you're doing now)
        console.log("=== TEST 1: Decode as (bytes) ===");
        try this.testDecodeAsBytes(actualData) {
            console.log("SUCCESS: Can decode as (bytes)");
        } catch {
            console.log("FAILED: Cannot decode as (bytes)");
        }
        console.log("");

        // Test 2: Try to decode as (bytes32, bytes) directly
        console.log("=== TEST 2: Decode as (bytes32, bytes) directly ===");
        try this.testDecodeAsBytes32AndBytes(actualData) {
            console.log("SUCCESS: Can decode as (bytes32, bytes) directly");
        } catch {
            console.log("FAILED: Cannot decode as (bytes32, bytes) directly");
        }
        console.log("");

        // Test 3: Try to decode as just bytes32 (operation only)
        console.log("=== TEST 3: Decode as (bytes32) only ===");
        try this.testDecodeAsBytes32Only(actualData) {
            console.log("SUCCESS: Can decode as (bytes32) only");
        } catch {
            console.log("FAILED: Cannot decode as (bytes32) only");
        }
        console.log("");

        // Test 4: Manual hex analysis
        console.log("=== TEST 4: Manual Hex Analysis ===");
        analyzeHexManually(actualData);
        console.log("");

        // Test 5: Try different data locations
        console.log("=== TEST 5: Different Data Locations ===");
        testDataLocations(actualData);
    }

    function testDecodeAsBytes(bytes calldata data) external pure {
        bytes memory result = abi.decode(data, (bytes));
        // If we get here, it worked
    }

    function testDecodeAsBytes32AndBytes(bytes calldata data) external pure {
        (bytes32 op, bytes memory params) = abi.decode(data, (bytes32, bytes));
        // If we get here, it worked
    }

    function testDecodeAsBytes32Only(bytes calldata data) external pure {
        bytes32 result = abi.decode(data, (bytes32));
        // If we get here, it worked
    }

    function analyzeHexManually(bytes memory data) internal view {
        // Extract first 32 bytes
        bytes32 first32Bytes;
        assembly {
            first32Bytes := mload(add(data, 32))
        }
        console.log("First 32 bytes (offset):", vm.toString(first32Bytes));
        
        // Extract second 32 bytes
        bytes32 second32Bytes;
        assembly {
            second32Bytes := mload(add(data, 64))
        }
        console.log("Next 32 bytes (length):", vm.toString(second32Bytes));
        
        // Extract third 32 bytes
        bytes32 third32Bytes;
        assembly {
            third32Bytes := mload(add(data, 96))
        }
        console.log("Next 32 bytes (operation?):", vm.toString(third32Bytes));
        
        // Check if first 32 bytes is 0x20 (32 in decimal)
        uint256 firstBytes = uint256(first32Bytes);
        console.log("First 32 bytes as uint256:", firstBytes);
        console.log("Is first 32 bytes = 32?", firstBytes == 32);
        
        // Check if second 32 bytes is 0xa0 (160 in decimal)
        uint256 secondBytes = uint256(second32Bytes);
        console.log("Second 32 bytes as uint256:", secondBytes);
        console.log("Is second 32 bytes = 160?", secondBytes == 160);
    }

    function testDataLocations(bytes memory data) internal view {
        // Test with calldata (what your contract receives)
        bytes calldata calldataData = data;
        console.log("Testing calldata version:");
        try this.testDecodeAsBytes(calldataData) {
            console.log("  SUCCESS: calldata decode as (bytes)");
        } catch {
            console.log("  FAILED: calldata decode as (bytes)");
        }

        // Test with memory (converted)
        bytes memory memoryData = data;
        console.log("Testing memory version:");
        try this.testDecodeAsBytesMemory(memoryData) {
            console.log("  SUCCESS: memory decode as (bytes)");
        } catch {
            console.log("  FAILED: memory decode as (bytes)");
        }
    }

    function testDecodeAsBytesMemory(bytes memory data) external pure {
        bytes memory result = abi.decode(data, (bytes));
        // If we get here, it worked
    }
}
