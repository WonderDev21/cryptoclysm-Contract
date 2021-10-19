// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/LevelStats.sol";
import "./DecimalMath.sol";

library Level {
    using DecimalMath for uint32;
    using DecimalMath for uint128;

    uint32 constant pointsUpgradeMultiplier = 10045;

    function generateNewLevel(LevelStats[] memory levels)
        internal
        pure
        returns (LevelStats memory)
    {
        require(levels.length > 0, "!initialized");
        if (levels.length == 1) {
            return firstLevelStats();
        } else {
            LevelStats memory lastLevel = levels[levels.length - 1];
            uint32 newLevel = lastLevel.level + 1;
            require(uint256(newLevel) == levels.length + 1, "level overflow");
            return
                LevelStats({
                    level: newLevel,
                    points: lastLevel.points.decimalMul32(
                        pointsUpgradeMultiplier
                    ),
                    xpForNextLevel: lastLevel.xpForNextLevel.decimalMul128(
                        levelMultiplier(newLevel)
                    ),
                    hitXpGainPercentage: hitXpGainPercentage(newLevel)
                });
        }
    }

    function firstLevelStats() internal pure returns (LevelStats memory) {
        return
            LevelStats({
                level: 1,
                points: 20,
                xpForNextLevel: 100,
                hitXpGainPercentage: hitXpGainPercentage(1)
            });
    }

    function levelMultiplier(uint32 level) internal pure returns (uint128) {
        if (level < 10) {
            return 15000;
        } else if (level == 10) {
            return 13000;
        } else if (level < 39) {
            return 11000;
        } else if (level < 79) {
            return 10500;
        } else {
            return 10100;
        }
    }

    function hitXpGainPercentage(uint32 level) internal pure returns (uint32) {
        if (level < 20) {
            return 500;
        } else if (level < 40) {
            return 300;
        } else if (level < 80) {
            return 200;
        } else {
            return 100;
        }
    }
}
