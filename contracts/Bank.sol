// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IBank.sol";
import "./interfaces/ICryptoClysm.sol";
import "./interfaces/IStakingRewards.sol";

contract Bank is OwnableUpgradeable, IBank {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Staked(address indexed token, address indexed user, uint256 amount);
    event Unstaked(address indexed token, address indexed user, uint256 amount);
    event StakingRewardSet(
        address indexed token,
        address indexed stakingReward
    );
    event Deposited(
        address indexed token,
        address indexed user,
        uint256 amount
    );
    event Withdrawn(
        address indexed token,
        address indexed user,
        uint256 amount
    );
    event RewardClaimed(
        address indexed token,
        address indexed user,
        uint256 amount
    );
    event OpenTokenTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    mapping(address => uint256) public treasuryFunds;
    mapping(address => address) public stakingRewards;
    mapping(address => bool) public openTokenManagers;
    mapping(address => mapping(address => uint256))
        public
        override openTokenBalance;
    address public cryptoClysm;
    address public creditToken;

    function initialize(address creditToken_) external initializer {
        __Ownable_init();

        creditToken = creditToken_;
    }

    function setCryptoClysm(address cryptoClysm_) external onlyOwner {
        cryptoClysm = cryptoClysm_;
    }

    function depositToken(
        address token,
        uint256 stakeAmount,
        uint256 openAmount
    ) external {
        _takeTokenFromUser(token, msg.sender, stakeAmount + openAmount);

        if (stakeAmount > 0) {
            _stakeToken(token, msg.sender, stakeAmount);
        }

        if (openAmount > 0) {
            openTokenBalance[token][msg.sender] += openAmount;
            emit Deposited(token, msg.sender, openAmount);
        }
    }

    function withdrawToken(
        address token,
        uint256 unstakeAmount,
        uint256 openAmount
    ) public {
        if (unstakeAmount > 0) {
            _unstakeToken(token, msg.sender, unstakeAmount);
        }

        if (openAmount > 0) {
            openTokenBalance[token][msg.sender] -= openAmount;
            emit Withdrawn(token, msg.sender, openAmount);
        }

        if (token == creditToken && cryptoClysm != address(0)) {
            ICryptoClysm(cryptoClysm).payUpkeep(msg.sender);
        }

        _sendTokenToUser(token, msg.sender, unstakeAmount + openAmount);
    }

    function claimReward(address stakingToken, bool withdraw)
        public
        returns (uint256 reward)
    {
        address rewardToken = IStakingRewards(stakingRewards[stakingToken])
            .rewardsToken();
        uint256 balance = IERC20Upgradeable(rewardToken).balanceOf(
            address(this)
        );

        IStakingRewards(stakingRewards[stakingToken]).getReward(msg.sender);

        reward =
            IERC20Upgradeable(rewardToken).balanceOf(address(this)) -
            balance;

        openTokenBalance[rewardToken][msg.sender] += reward;

        emit RewardClaimed(rewardToken, msg.sender, reward);

        if (withdraw) {
            withdrawToken(rewardToken, 0, reward);
        }
    }

    function claimRewards(address[] calldata stakingTokens, bool withdraw)
        external
        returns (uint256 reward)
    {
        for (uint256 i = 0; i < stakingTokens.length; i += 1) {
            reward += claimReward(stakingTokens[i], withdraw);
        }
    }

    function setStakingReward(address stakingToken, address stakingReward)
        external
        onlyOwner
    {
        stakingRewards[stakingToken] = stakingReward;

        emit StakingRewardSet(stakingToken, stakingReward);
    }

    function transferOpenToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override {
        require(openTokenManagers[msg.sender], "No permission");
        require(amount > 0, "Invalid amount");
        if (from == address(0)) {
            treasuryFunds[token] -= amount;
        } else {
            openTokenBalance[token][from] -= amount;
        }
        if (to == address(0)) {
            treasuryFunds[token] += amount;
        } else {
            openTokenBalance[token][to] += amount;
        }

        emit OpenTokenTransfer(token, from, to, amount);
    }

    function withdrawTreasuryFunds(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    function setOpenTokenManager(address tokenManager, bool enable)
        external
        onlyOwner
    {
        require(tokenManager != address(0), "Invalid token manager");
        openTokenManagers[tokenManager] = enable;
    }

    function _stakeToken(
        address token,
        address user,
        uint256 amount
    ) internal {
        address stakingReward = stakingRewards[token];
        require(stakingReward != address(0), "No reward pool");

        IStakingRewards(stakingReward).stake(user, amount);

        emit Staked(token, user, amount);
    }

    function _unstakeToken(
        address token,
        address user,
        uint256 amount
    ) internal {
        address stakingReward = stakingRewards[token];
        require(stakingReward != address(0), "No reward pool");

        IStakingRewards(stakingReward).withdraw(user, amount);

        emit Unstaked(token, user, amount);
    }

    function _takeTokenFromUser(
        address token,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "Invalid amount");
        uint256 currentBal = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransferFrom(user, address(this), amount);
        return IERC20Upgradeable(token).balanceOf(address(this)) - currentBal;
    }

    function _sendTokenToUser(
        address token,
        address user,
        uint256 amount
    ) internal {
        require(amount > 0, "Invalid amount");
        IERC20Upgradeable(token).safeTransfer(user, amount);
    }
}
