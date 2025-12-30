const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");

require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24", // 或者你使用的版本
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true  // <--- 添加这一行, 启用IR优化,合约内容更复杂时可以优化代码体积
    }
  },
  networks: {
    // Hardhat 内置网络（用于测试）
    hardhat: {
      chainId: 31337,
    },
    // 本地开发网络
    localhost: {
      url: "http://127.0.0.1:8545", // Hardhat 节点默认端口
      chainId: 31337, // Hardhat 默认链ID
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PK],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  }
};
