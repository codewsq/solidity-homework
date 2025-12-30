const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");

require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");

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
  localhost: {
    url: "http://127.0.0.1:8545"
  },
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  }
};
