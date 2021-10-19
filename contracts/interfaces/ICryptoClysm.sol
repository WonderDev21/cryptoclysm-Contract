// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IArmoryNft.sol";
import "./ITreasury.sol";
import "../datatypes/UserStats.sol";

interface ICryptoClysm {
    function userStats(address user) external view returns (UserStats memory);

    function payUpkeep(address user) external;
}
