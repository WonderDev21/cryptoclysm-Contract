// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArmoryNft {
    function mintArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        );

    function burnArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        );
}
