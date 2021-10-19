import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';
import { Bank } from '../src/types';

const deployBank: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer, creditToken, proxyAdmin } = await getNamedAccounts();

  await deploy('Bank', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
    proxy: {
      owner: proxyAdmin,
      proxyContract: 'TransparentUpgradeableProxy',
    },
  });

  const Bank = await ethers.getContract<Bank>('Bank');

  await Bank.initialize(creditToken);
};

export default deployBank;
deployBank.tags = ['Bank'];
