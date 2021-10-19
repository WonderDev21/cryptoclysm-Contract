// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function transferToken(
        address token,
        address receipient,
        uint256 amount
    ) external;
}
