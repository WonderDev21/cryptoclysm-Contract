import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import 'hardhat-dependency-compiler';
import '@typechain/hardhat';
import 'solidity-coverage';
import 'dotenv/config';

export default {
  networks: {
    hardhat: {
      gas: 10000000,
      accounts: {
        accountsBalance: '100000000000000000000000000',
        count: 200,
      },
      timeout: 1000000,
    },
    mainnet: {
      url: 'https://api.harmony.one',
      chainId: 1666600000,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
    },
    testnet: {
      url: 'https://api.s0.b.hmny.io',
      chainId: 1666700000,
      accounts: [process.env.TESTNET_PRIVATE_KEY],
    },
    rinkeby: {
      url: 'https://eth-rinkeby.alchemyapi.io/v2/cGlRTYsceipoNitTHaT0Epqp_YtORWAi',
      chainId: 4,
      accounts: [
        '0x92f727b0ca5ee964daf4452632151dd806a13fbc345389c0da60889e18a1efcf',
      ],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    creditToken: {
      1666700000: '0x561277A9c06C3B20ECfD2892CbDdC2Cd6EE7E9de',
      1666600000: '0xDfb01A88D1e6099B42c9Bae38F8070027143b850',
      4: '0xDfb01A88D1e6099B42c9Bae38F8070027143b850',
    },
    gameToken: {
      1666700000: '0xdC97423e9c6129640Fe72ca6909E8D032029C1e0',
      1666600000: '0x491614c6d1A7cc8b0A3Ed0bBdecd35a0110c11e6',
      4: '0xDfb01A88D1e6099B42c9Bae38F8070027143b850',
    },
    proxyAdmin: {
      1666700000: '0xc105124ff3c4208a03696d779019eF3171633186',
      1666600000: '0xEf9e24bA2C2a02b2E6DcB0D797beefa90eF49790',
      4: '0xFC0Fb7c5ecDC08FAE522372c385577c09ca64C3c',
    },
    rewardDistribution: {
      1666700000: '0xc105124ff3c4208a03696d779019eF3171633186',
      1666600000: '0xEf9e24bA2C2a02b2E6DcB0D797beefa90eF49790',
      4: '0xFC0Fb7c5ecDC08FAE522372c385577c09ca64C3c',
    },
  },
  typechain: {
    outDir: 'src/types',
    target: 'ethers-v5',
  },
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  dependencyCompiler: {
    paths: [
      '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol',
    ],
  },
};
