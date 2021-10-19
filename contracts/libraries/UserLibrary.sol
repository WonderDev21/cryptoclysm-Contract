// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/UserStats.sol";
import "../datatypes/UserAttackInfo.sol";
import "../datatypes/TimeIncreaseValue.sol";
import "./StaminaLibrary.sol";
import "./EnergyLibrary.sol";

library UserLibrary {
    using StaminaLibrary for TimeIncreaseValue;
    using EnergyLibrary for TimeIncreaseValue;

    function getUserAttackInfo(UserStats storage userStats)
        internal
        returns (UserAttackInfo memory)
    {
        userStats.stamina.updateStamina();
        userStats.energy.updateEnergy();

        return
            UserAttackInfo({
                hp: userStats.hp,
                energy: userStats.energy.value,
                stamina: userStats.stamina.value,
                attack: (
                    userStats.unpaidUpkeep > 0
                        ? userStats.attack
                        : userStats.attack + userStats.armoryAttack
                ) + userStats.alliance / 10,
                defense: (
                    userStats.unpaidUpkeep > 0
                        ? userStats.defense
                        : userStats.defense + userStats.armoryDefense
                ) + userStats.alliance / 10
            });
    }
}
