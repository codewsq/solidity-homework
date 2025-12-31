const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");

require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const { hardhatVerify } = require("@nomicfoundation/hardhat-verify")

const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent("http://127.0.0.1:7897"); // 如果你有代理服务器，可以设置代理地址
setGlobalDispatcher(proxyAgent);

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
      url: process.env.INFURA_API_KEY,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY],
      chainId: 11155111, // Sepolia 测试网络的链ID
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  },
  // verify: {
  //   etherscan: {
  //     apiKey: process.env.ETHERSCAN_API_KEY,
  //   },
  // },
  // plugins: [
  //   hardhatVerify,
  // ],
};
