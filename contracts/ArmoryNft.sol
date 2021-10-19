// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./datatypes/ArmoryMetadata.sol";
import "./libraries/DecimalMath.sol";
import "./interfaces/IArmoryNft.sol";
import "./interfaces/ICryptoClysm.sol";

contract ArmoryNft is ERC1155Upgradeable, OwnableUpgradeable, IArmoryNft {
    using DecimalMath for uint256;

    event NewArmoryRegistered(uint256 indexed id, ArmoryMetadata metadata);
    event ArmoryUpdated(uint256 indexed id, ArmoryMetadata metadata);

    mapping(uint256 => ArmoryMetadata) public metadata;
    mapping(address => mapping(uint256 => uint256[])) public priceHistory;
    uint256 public armoryLength;
    uint256 public costMultiplier;
    address public cryptoClysm;

    modifier onlyCryptoClysm() {
        require(msg.sender == cryptoClysm, "Not CryptoClysm");
        _;
    }

    modifier validArmory(uint256 id) {
        require(id < armoryLength, "invalid armory");
        _;
    }

    function initialize(
        string memory uri_,
        address cryptoClysm_,
        uint256 costMultiplier_
    ) public initializer {
        require(cryptoClysm != address(0), "0x!");
        require(costMultiplier_ > 0, "zero!");

        __ERC1155_init(uri_);
        __Ownable_init();

        costMultiplier = costMultiplier_;
        cryptoClysm = cryptoClysm_;
    }

    function registerNewArmory(ArmoryMetadata calldata newMetadata)
        external
        onlyOwner
    {
        metadata[armoryLength] = newMetadata;

        emit NewArmoryRegistered(armoryLength, newMetadata);

        armoryLength += 1;
    }

    function updateArmory(uint256 id, ArmoryMetadata calldata newMetadata)
        external
        onlyOwner
        validArmory(id)
    {
        metadata[id] = newMetadata;

        emit ArmoryUpdated(id, newMetadata);
    }

    function mintArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        override
        validArmory(id)
        onlyCryptoClysm
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        )
    {
        UserStats memory userStats = ICryptoClysm(cryptoClysm).userStats(user);
        require(userStats.level >= metadata[id].minLevel, "no exp");
        _mint(user, id, amount, "");

        (uint256[] memory newPrices, uint256 price) = getPurchasePrices(
            user,
            id,
            amount
        );

        uint256[] storage userPriceHistory = priceHistory[user][id];
        for (uint256 i = 0; i < amount; i += 1) {
            userPriceHistory.push(newPrices[i]);
        }

        ArmoryMetadata memory tokenMetadata = metadata[id];

        return (
            price,
            tokenMetadata.upkeep * amount,
            tokenMetadata.attack * uint32(amount),
            tokenMetadata.defense * uint32(amount)
        );
    }

    function burnArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        override
        validArmory(id)
        onlyCryptoClysm
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        )
    {
        _burn(user, id, amount);

        uint256 price = getSellPrice(user, id, amount);

        uint256[] storage userPriceHistory = priceHistory[user][id];
        for (uint256 i = 0; i < amount; i += 1) {
            userPriceHistory.pop();
        }

        ArmoryMetadata memory tokenMetadata = metadata[id];

        return (
            price,
            tokenMetadata.upkeep * amount,
            tokenMetadata.attack * uint32(amount),
            tokenMetadata.defense * uint32(amount)
        );
    }

    function setCostMultiplier(uint256 costMultiplier_) external onlyOwner {
        require(costMultiplier_ > 0, "zero!");

        costMultiplier = costMultiplier_;
    }

    function getPurchasePrices(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        view
        validArmory(id)
        returns (uint256[] memory newPrices, uint256 totalPrice)
    {
        uint256[] memory userPriceHistory = priceHistory[account][id];

        if (amount > 0) {
            newPrices = new uint256[](amount);
            uint256 price = userPriceHistory.length == 0
                ? metadata[id].cost
                : userPriceHistory[userPriceHistory.length - 1].decimalMul(
                    costMultiplier
                );
            newPrices[0] = price;
            totalPrice = price;
            for (uint256 i = 1; i < amount; i += 1) {
                price = price.decimalMul(costMultiplier);
                newPrices[i] = price;
                totalPrice += price;
            }
        }
    }

    function getSellPrice(
        address account,
        uint256 id,
        uint256 amount
    ) public view validArmory(id) returns (uint256 totalPrice) {
        uint256[] memory userPriceHistory = priceHistory[account][id];
        require(userPriceHistory.length >= amount, "overflow");

        if (userPriceHistory.length > 0) {
            uint256 i = userPriceHistory.length - 1;

            while (amount > 0) {
                totalPrice += userPriceHistory[i] / 2;
                i -= 1;
                amount -= 1;
            }
        }
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        revert("cannot transfer");
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        revert("cannot transfer");
    }
}
