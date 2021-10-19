// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ArmoryMetadata {
    bool isArtifactWeapon;
    uint32 minLevel;
    uint32 minChapter;
    uint32 attack;
    uint32 defense;
    uint256 cost;
    uint256 upkeep;
}
