// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/TimeIncreaseValue.sol";
import "./DecimalMath.sol";

library EnergyLibrary {
    // Increase 1 stamina every 2 minutes
    uint64 constant ENERGY_UPDATE_DURATION = 5 minutes;
    uint64 constant ENERGY_INCREASE_PERCENTAGE = 10; // 10%

    function updateEnergy(TimeIncreaseValue storage energy) internal {
        require(energy.maxValue > 0, "No energy");

        uint64 timePassed = uint64(block.timestamp) - energy.lastUpdatedTime;
        uint64 ticks = timePassed / ENERGY_UPDATE_DURATION;
        uint64 newValue = energy.value +
            (energy.maxValue * ticks * ENERGY_INCREASE_PERCENTAGE) /
            100;
        energy.value = newValue > energy.maxValue ? energy.maxValue : newValue;
        energy.lastUpdatedTime =
            energy.lastUpdatedTime +
            ticks *
            ENERGY_UPDATE_DURATION;
    }

    function getEnergy(TimeIncreaseValue memory energy)
        internal
        view
        returns (uint64)
    {
        if (energy.maxValue == 0) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - energy.lastUpdatedTime;
        uint64 ticks = timePassed / ENERGY_UPDATE_DURATION;
        uint64 newValue = energy.value +
            (energy.maxValue * ticks * ENERGY_INCREASE_PERCENTAGE) /
            100;

        return newValue > energy.maxValue ? energy.maxValue : newValue;
    }
}
