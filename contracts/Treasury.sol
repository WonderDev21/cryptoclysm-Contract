// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/ITreasury.sol";

contract Treasury is OwnableUpgradeable, ITreasury {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public bank;

    modifier onlyBank() {
        require(msg.sender == bank, "not bank");
        _;
    }

    constructor(address bank_) {
        require(bank_ != address(0), "0x!");

        bank = bank_;
    }

    function transferToken(
        address token,
        address receipient,
        uint256 amount
    ) external override onlyBank {
        IERC20Upgradeable(token).safeTransfer(receipient, amount);
    }
}
