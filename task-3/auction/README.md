# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

```shell
# 挂载调试可升级合约对象hardhat-deploy
# 1.安装依赖
npm install -D hardhat-deploy
npm install --save-dev hardhat-deploy
# 2.在hardhat.config.js中导入 -  require("hardhat-deploy");
# 3.在hardhat.config.js中配置
# 4.尝试启动
npx hardhat deploy
# 升级合约的标准依赖库
npm install @openzeppelin/contracts-upgradeable
# 安装hardhat部署依赖
npm install -d @openzeppelin/hardhat-upgrades
# 在hardhat.config.js中导入 - require("@openzeppelin/hardhat-upgrades");
# 编写01_deploy_nft_auction.js
# 启动部署
npx hardhat deploy [--tags upgrade] [--network bscTestnet]

```