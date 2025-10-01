// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Operator } from '../../utils/Operator.sol';

contract TestOperator is Operator {
    uint256 public nonce;

    constructor(address operator) {
        _addOperator(operator);
    }

    function testOperatorable() external onlyRole(uint8(Roles.OPERATOR)) {
        nonce++;
    }

    function operatorRole() external pure returns (uint8) {
        return uint8(Roles.OPERATOR);
    }
}
