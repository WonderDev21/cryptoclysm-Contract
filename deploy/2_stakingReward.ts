import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';
import { Bank, StakingRewards } from '../src/types';

const deployBank: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer, creditToken, gameToken, rewardDistribution } =
    await getNamedAccounts();

  const Bank = await ethers.getContract<Bank>('Bank');

  await deploy('StakingRewards', {
    from: deployer,
    args: [rewardDistribution, creditToken, Bank.address],
    log: true,
  });

  const StakingRewards = await ethers.getContract<StakingRewards>(
    'StakingRewards',
  );

  await Bank.setStakingReward(gameToken, StakingRewards.address);
};

export default deployBank;
deployBank.tags = ['StakingRewards'];
