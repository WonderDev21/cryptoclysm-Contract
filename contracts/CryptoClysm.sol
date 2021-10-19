// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/Level.sol";
import "./libraries/UserLibrary.sol";
import "./libraries/DecimalMath.sol";
import "./datatypes/LevelStats.sol";
import "./datatypes/UserStats.sol";
import "./datatypes/UserAttackInfo.sol";
import "./interfaces/IArmoryNft.sol";
import "./interfaces/IBank.sol";
import "./interfaces/ICryptoClysm.sol";

contract CryptoClysm is ICryptoClysm, OwnableUpgradeable {
    using Level for LevelStats[];
    using UserLibrary for UserStats;
    using DecimalMath for uint128;
    using DecimalMath for uint256;

    enum HitResult {
        WIN,
        LOSE,
        DRAW
    }

    uint64 constant UPKEEP_PERIOD = 1 days;

    uint256 public totalUsers;
    LevelStats[] public levels;

    mapping(address => UserStats) private _userStats;
    address public armoryNft;
    address public creditToken;
    address public bank;

    modifier payUpkeepChecker(address user) {
        _payUpkeep(user);
        _;
    }

    function initialize(address creditToken_, address armoryNft_)
        public
        initializer
    {
        __Ownable_init();

        require(creditToken_ != address(0), "0x!");
        require(armoryNft_ != address(0), "0x!");

        creditToken = creditToken_;
        armoryNft = armoryNft_;

        // Initialize zero level
        LevelStats memory stats;
        levels.push(stats);

        LevelStats memory newLevel = levels.generateNewLevel();
        levels.push(newLevel);
    }

    function payUpkeep(address user) external override {
        _payUpkeep(user);
    }

    function buyArmory(uint256 armoryId, uint256 amount) external {
        _payUpkeep(msg.sender);
        (
            uint256 price,
            uint256 upkeep,
            uint32 attack,
            uint32 defense
        ) = IArmoryNft(armoryNft).mintArmory(msg.sender, armoryId, amount);
        IBank(bank).transferOpenToken(
            creditToken,
            msg.sender,
            address(0),
            price
        );
        _increaseUserArmory(msg.sender, upkeep, attack, defense);
    }

    function sellArmory(uint256 armoryId, uint256 amount) external {
        _payUpkeep(msg.sender);
        (
            uint256 price,
            uint256 upkeep,
            uint32 attack,
            uint32 defense
        ) = IArmoryNft(armoryNft).mintArmory(msg.sender, armoryId, amount);
        IBank(bank).transferOpenToken(
            creditToken,
            address(0),
            msg.sender,
            price
        );
        _decreaseUserArmory(msg.sender, upkeep, attack, defense);
    }

    function hit(address user) external {
        require(msg.sender == tx.origin, "Not EOD");

        _payUpkeep(msg.sender);
        _payUpkeep(user);

        UserStats storage attacker = _userStats[msg.sender];
        UserStats storage defenser = _userStats[msg.sender];
        require(
            attacker.level > 0 && defenser.level > 0,
            "User not registered"
        );

        UserAttackInfo memory attackerInfo = attacker.getUserAttackInfo();
        UserAttackInfo memory defenserInfo = defenser.getUserAttackInfo();

        require(attackerInfo.stamina > 0, "No stamina");
        require(attackerInfo.hp > 0 && defenserInfo.hp > 0, "Dead");

        HitResult result = attackerInfo.attack > defenserInfo.defense
            ? HitResult.WIN
            : (
                attackerInfo.attack < defenserInfo.defense
                    ? HitResult.LOSE
                    : HitResult.DRAW
            );
        uint32 attackPoints = ((
            result == HitResult.WIN
                ? attackerInfo.attack - defenserInfo.defense
                : defenserInfo.defense - attackerInfo.attack
        ) * 200) / (attackerInfo.attack + defenserInfo.defense);

        uint64 damage = attackPoints * 120;
        uint64 loseHp = damage / 10;

        bool attackerDead;
        bool defenserDead;

        if (result == HitResult.WIN) {
            (attackerDead, defenserDead) = _getDamage(
                attacker,
                defenser,
                loseHp,
                damage
            );
            if (attackerDead) {
                result = HitResult.DRAW;
            }
        } else if (result == HitResult.LOSE) {
            (attackerDead, defenserDead) = _getDamage(
                attacker,
                defenser,
                damage,
                loseHp
            );
            if (defenserDead) {
                result = HitResult.DRAW;
            }
        }

        _gainExp(attacker, result == HitResult.WIN, true);
        _gainExp(defenser, result == HitResult.LOSE, false);

        if (result == HitResult.WIN) {
            _takeOpenCredit(user, msg.sender, defenserDead);
        } else if (result == HitResult.LOSE) {
            _takeOpenCredit(msg.sender, user, attackerDead);
        }
        if (attacker.stamina.value > 0) {
            attacker.stamina.value -= 1;
        }
    }

    function _takeOpenCredit(
        address from,
        address to,
        bool full
    ) internal {
        uint256 availableCredit = IBank(bank).openTokenBalance(
            creditToken,
            from
        );

        uint256 creditTaken = full
            ? availableCredit
            : availableCredit.decimalMul(1000);
        if (creditTaken > 0) {
            IBank(bank).transferOpenToken(creditToken, from, to, creditTaken);
        }
    }

    function _getDamage(
        UserStats storage attacker,
        UserStats storage defenser,
        uint64 attackerDamage,
        uint64 defenserDamage
    ) internal returns (bool attackerDead, bool defenserDead) {
        if (attacker.hp > attackerDamage) {
            attacker.hp -= attackerDamage;
        } else {
            attacker.hp = 0;
            attackerDead = true;
        }

        if (defenser.hp > defenserDamage) {
            defenser.hp -= defenserDamage;
        } else {
            defenser.hp = 0;
            defenserDead = true;
        }
    }

    function _gainExp(
        UserStats storage user,
        bool win,
        bool attacker
    ) internal {
        uint128 increasePct = (win ? 500 : 100) +
            (attacker ? levels[user.level].hitXpGainPercentage : 0);

        uint128 newExp = levels[user.level].xpForNextLevel.decimalMul128(
            increasePct
        );
        user.exp += newExp;

        if (user.exp >= levels[user.level].xpForNextLevel) {
            user.exp -= levels[user.level].xpForNextLevel;
            _upgradeUserLevel(user);
        }
    }

    function _increaseUserArmory(
        address user,
        uint256 upkeep,
        uint32 attack,
        uint32 defense
    ) internal {
        UserStats storage myStats = _userStats[user];
        myStats.upkeep += upkeep;
        myStats.armoryAttack += attack;
        myStats.armoryDefense += defense;
    }

    function _decreaseUserArmory(
        address user,
        uint256 upkeep,
        uint32 attack,
        uint32 defense
    ) internal {
        UserStats storage myStats = _userStats[user];
        myStats.upkeep -= upkeep;
        myStats.armoryAttack -= attack;
        myStats.armoryDefense -= defense;
    }

    function _payUpkeep(address user) internal {
        UserStats storage myStats = _userStats[user];
        if (myStats.upkeep == 0) {
            return;
        }

        uint64 unpaidDays = (_getBlockTimestamp() / UPKEEP_PERIOD) -
            myStats.lastUpkeepPaidIndex;
        myStats.lastUpkeepPaidIndex = _getBlockTimestamp() / UPKEEP_PERIOD;
        uint256 totalUpkeepRequired = myStats.unpaidUpkeep +
            (myStats.upkeep * uint256(unpaidDays));
        uint256 availableCredit = IBank(bank).openTokenBalance(
            creditToken,
            user
        );
        if (availableCredit >= totalUpkeepRequired) {
            IBank(bank).transferOpenToken(
                creditToken,
                user,
                address(0),
                totalUpkeepRequired
            );
            myStats.unpaidUpkeep = 0;
        } else {
            IBank(bank).transferOpenToken(
                creditToken,
                user,
                address(0),
                availableCredit
            );
            myStats.unpaidUpkeep = totalUpkeepRequired - availableCredit;
        }
    }

    function register() external {
        _registerUser(msg.sender);
    }

    function _registerUser(address user) internal {
        require(_userStats[user].level == 0, "exist!");

        UserStats storage myStats = _userStats[user];

        _upgradeUserLevel(myStats);

        myStats.lastUpkeepPaidIndex = _getBlockTimestamp() / UPKEEP_PERIOD;
    }

    function _upgradeUserLevel(UserStats storage myStats) internal {
        myStats.level += 1;
        if (levels.length == myStats.level) {
            LevelStats memory newLevel = levels.generateNewLevel();
            levels.push(newLevel);
        }

        uint32 points = levels[myStats.level].points;

        myStats.hp = uint64(points) * 250;
        myStats.attack = points;
        myStats.defense = points;
        myStats.energy.maxValue = uint64(points) * 100;
        myStats.energy.value = myStats.energy.maxValue;
        myStats.energy.lastUpdatedTime = _getBlockTimestamp();
        myStats.stamina.maxValue = uint64(points) / 5;
        myStats.stamina.value = myStats.stamina.maxValue;
        myStats.stamina.lastUpdatedTime = _getBlockTimestamp();
    }

    function userStats(address user)
        external
        view
        override
        returns (UserStats memory)
    {
        return _userStats[user];
    }

    function _getBlockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}
