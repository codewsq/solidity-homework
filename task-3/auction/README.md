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

# 基础测试 - 需要注释掉02_upgrade_nft_auction.js最后一行依赖
npx hardhat test test/NftAuction.js
# 测试拍卖合约 第一版本功能
npx hardhat test test/TestNftAuction.js 
# 测试拍卖合约 第二版本功能，升级内容有：预言机喂价、新增ERC20代币拍卖
npx hardhat test test/TestNftAuctionV2.js
```

```bash
# 1. 编译合约
npx hardhat compile

# 2. 在本地测试部署（确保一切正常）
npx hardhat ignition deploy ./ignition/modules/MyToken.js --network localhost

# 3. 部署到Sepolia测试网
npx hardhat ignition deploy ./ignition/modules/NftAuctionV2.js --network sepolia

# 4. 可选：验证合约（需要配置Etherscan API密钥）
npx hardhat verify --network sepolia 0xfcfb7f3846913843fda6eB3D1897481520f00489

# 5. 可选：运行测试
npx hardhat test
```