// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/TimeIncreaseValue.sol";
import "./DecimalMath.sol";

library StaminaLibrary {
    // Increase 1 stamina every 2 minutes
    uint64 constant STAMINA_UPDATE_DURATION = 2 minutes;
    uint64 constant STAMINA_INCREASE = 1;

    function updateStamina(TimeIncreaseValue storage stamina) internal {
        require(stamina.maxValue > 0, "No stamina");

        uint64 timePassed = uint64(block.timestamp) - stamina.lastUpdatedTime;
        uint64 ticks = timePassed / STAMINA_UPDATE_DURATION;
        uint64 newValue = stamina.value + ticks * STAMINA_INCREASE;
        stamina.value = newValue > stamina.maxValue
            ? stamina.maxValue
            : newValue;
        stamina.lastUpdatedTime =
            stamina.lastUpdatedTime +
            ticks *
            STAMINA_UPDATE_DURATION;
    }

    function getStamina(TimeIncreaseValue memory stamina)
        internal
        view
        returns (uint64)
    {
        if (stamina.maxValue == 0) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - stamina.lastUpdatedTime;
        uint64 ticks = timePassed / STAMINA_UPDATE_DURATION;
        uint64 newValue = stamina.value + ticks;

        return newValue > stamina.maxValue ? stamina.maxValue : newValue;
    }
}
