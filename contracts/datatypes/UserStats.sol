// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimeIncreaseValue.sol";

struct UserStats {
    TimeIncreaseValue energy;
    TimeIncreaseValue stamina;
    uint64 hp;
    uint32 level;
    uint64 lastUpkeepPaidIndex;
    uint32 attack;
    uint32 armoryAttack;
    uint32 defense;
    uint32 armoryDefense;
    uint32 alliance;
    uint128 exp;
    uint256 upkeep;
    uint256 unpaidUpkeep;
}
