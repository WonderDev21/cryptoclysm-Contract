// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank {
    function openTokenBalance(address token, address user)
        external
        view
        returns (uint256);

    function transferOpenToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}
