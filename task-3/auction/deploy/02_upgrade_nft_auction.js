const { deployments, upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();

  // 读取 .cache/proxyNftAuction.json 文件中的合约地址和ABI
  const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
  const storeData = fs.readFileSync(storePath, "utf-8");
  const { proxyAddress, implAddress, abi } = JSON.parse(storeData);

  // 升级版的业务合约
  const NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");

  // 使用代理合约地址和ABI，升级业务合约
  const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress, NftAuctionV2, { deployer });
  await nftAuctionProxyV2.waitForDeployment();

  const proxyAddressV2 = await nftAuctionProxyV2.getAddress()
  console.log("升级后的代理合约地址：", proxyAddressV2);
  console.log("升级后的逻辑合约地址：", await upgrades.erc1967.getImplementationAddress(proxyAddressV2));
  // 保存代理合约地址
  // fs.writeFileSync(
  //   storePath,
  //   JSON.stringify({
  //     proxyAddress: proxyAddressV2,
  //     implAddress,
  //     abi,
  //   })
  // );
  // 保存合约地址和ABI 到 hardhat-deploy 的部署记录中，供测试使用
  await save("NftAuctionProxy", {
    abi,
    address: proxyAddressV2,
  });
}
// 关键点：这里定义依赖，确保 ["deployNftAuction"] 先运行
module.exports.tags = ["upgradeNftAuction"];
module.exports.dependencies = ["deployNftAuction"]; // <--- 确保有这一行，声明依赖关系

