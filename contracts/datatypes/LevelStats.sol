// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct LevelStats {
    uint32 level;
    uint32 points;
    uint32 hitXpGainPercentage;
    uint128 xpForNextLevel;
}
