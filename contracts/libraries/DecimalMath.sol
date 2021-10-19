// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DecimalMath {
    uint32 constant DENOMINATOR = 10000;

    function decimalMul32(uint32 x, uint32 y) public pure returns (uint32) {
        return (x * y) / DENOMINATOR;
    }

    function decimalMul128(uint128 x, uint128 y) public pure returns (uint128) {
        return (x * y) / uint128(DENOMINATOR);
    }

    function decimalMul(uint256 x, uint256 y) public pure returns (uint256) {
        return (x * y) / uint256(DENOMINATOR);
    }
}
