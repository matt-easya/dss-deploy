// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract TestPayloadDecoding is Script {
    // Operation constants (matching Controller)
    bytes32 constant OP_DEPOSIT_AND_SWAP = keccak256("deposit_and_swap");
    bytes32 constant OP_OPEN_CDP = keccak256("open_cdp");
    bytes32 constant OP_DEPOSIT_COLLATERAL = keccak256("deposit_collateral");

    function run() external view {
        console.log("=== PAYLOAD DECODING TESTS ===\n");

        // Test 1: Your actual payload from the debug log
        testActualPayload();
        
        // Test 2: Simple operation-only encoding (like working example)
        testSimpleOperationOnly();
        
        // Test 3: Complex encoding (operation + params)
        testComplexEncoding();
        
        // Test 4: Edge cases
        testEdgeCases();
    }

    function testActualPayload() internal view {
        console.log("--- Test 1: Your Actual Payload ---");
        
        // This is the exact payload from your debug log
        bytes memory actualPayload = hex"e77d2bd163c1d1e0f6d02bd9b28f5b1b0efd4ecd39aa2db3cc6d3d720b6495a2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000405852502d410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000";
        
        console.log("Payload length:", actualPayload.length);
        console.log("Payload hex: 0x", vm.toString(actualPayload));
        
        // Try simple decode (operation only)
        bytes32 op1 = decodeOperationOnly(actualPayload);
        console.log("Simple decode SUCCESS:");
        console.log("  Operation:", vm.toString(op1));
        console.log("  Matches OP_DEPOSIT_AND_SWAP:", op1 == OP_DEPOSIT_AND_SWAP);
        
        // Try complex decode (operation + params)
        (bytes32 op2, bytes memory params) = decodeOperationAndParams(actualPayload);
        console.log("Complex decode SUCCESS:");
        console.log("  Operation:", vm.toString(op2));
        console.log("  Params length:", params.length);
        console.log("  Params hex: 0x", vm.toString(params));
        
        // Try to decode params
        (bytes32 ilk, uint256 daiToDraw) = decodeParams(params);
        console.log("  Params decode SUCCESS:");
        console.log("    Ilk:", vm.toString(ilk));
        console.log("    DaiToDraw:", daiToDraw);
        
        console.log("");
    }

    function testSimpleOperationOnly() internal view {
        console.log("--- Test 2: Simple Operation Only ---");
        
        // Encode just the operation (like the working example)
        bytes memory simplePayload = abi.encode(OP_DEPOSIT_AND_SWAP);
        
        console.log("Simple payload length:", simplePayload.length);
        console.log("Simple payload hex: 0x", vm.toString(simplePayload));
        
        // Try simple decode
        bytes32 op1 = decodeOperationOnly(simplePayload);
        console.log("Simple decode SUCCESS:");
        console.log("  Operation:", vm.toString(op1));
        console.log("  Matches OP_DEPOSIT_AND_SWAP:", op1 == OP_DEPOSIT_AND_SWAP);
        
        // Try complex decode (should fail)
        console.log("Complex decode attempt:");
        console.log("  (This will likely fail with simple payload)");
        
        console.log("");
    }

    function testComplexEncoding() internal view {
        console.log("--- Test 3: Fresh Complex Encoding ---");
        
        // Create fresh encoding of operation + params
        bytes32 testIlk = "XRP-A";
        uint256 testDaiToDraw = 1 ether;
        bytes memory testParams = abi.encode(testIlk, testDaiToDraw);
        bytes memory complexPayload = abi.encode(OP_DEPOSIT_AND_SWAP, testParams);
        
        console.log("Fresh payload length:", complexPayload.length);
        console.log("Fresh payload hex: 0x", vm.toString(complexPayload));
        
        // Try simple decode
        bytes32 op1 = decodeOperationOnly(complexPayload);
        console.log("Simple decode SUCCESS:");
        console.log("  Operation:", vm.toString(op1));
        console.log("  Matches OP_DEPOSIT_AND_SWAP:", op1 == OP_DEPOSIT_AND_SWAP);
        
        // Try complex decode
        (bytes32 op2, bytes memory params) = decodeOperationAndParams(complexPayload);
        console.log("Complex decode SUCCESS:");
        console.log("  Operation:", vm.toString(op2));
        console.log("  Params length:", params.length);
        console.log("  Params hex: 0x", vm.toString(params));
        
        // Try to decode params
        (bytes32 ilk, uint256 daiToDraw) = decodeParams(params);
        console.log("  Params decode SUCCESS:");
        console.log("    Ilk:", vm.toString(ilk));
        console.log("    DaiToDraw:", daiToDraw);
        console.log("    DaiToDraw matches 1 ether:", daiToDraw == 1 ether);
        
        console.log("");
    }

    function testEdgeCases() internal view {
        console.log("--- Test 4: Edge Cases ---");
        
        // Empty payload - skip this test as it will fail
        console.log("Empty payload: (skipping - will fail)");
        
        // Too short payload - skip this test as it will fail  
        console.log("Too short payload (31 bytes): (skipping - will fail)");
        
        // Just 32 bytes (operation only)
        console.log("32-byte payload (operation only):");
        bytes memory opOnlyPayload = abi.encodePacked(OP_DEPOSIT_AND_SWAP);
        bytes32 op = decodeOperationOnly(opOnlyPayload);
        console.log("  SUCCESS:", vm.toString(op));
        console.log("  Matches OP_DEPOSIT_AND_SWAP:", op == OP_DEPOSIT_AND_SWAP);
        
        console.log("");
    }

    // Helper functions for decoding
    function decodeOperationOnly(bytes memory data) internal pure returns (bytes32 op) {
        return abi.decode(data, (bytes32));
    }

    function decodeOperationAndParams(bytes memory data) internal pure returns (bytes32 op, bytes memory params) {
        return abi.decode(data, (bytes32, bytes));
    }

    function decodeParams(bytes memory params) internal pure returns (bytes32 ilk, uint256 daiToDraw) {
        return abi.decode(params, (bytes32, uint256));
    }
}
