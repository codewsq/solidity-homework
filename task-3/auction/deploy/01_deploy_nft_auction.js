const { deployments, upgrades, ethers } = require("hardhat");

const fs = require("fs");
const path = require("path");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, save } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("部署用户地址：", deployer)

  // 获取合约工厂
  const NftAuction = await ethers.getContractFactory("NftAuction");

  // 通过代理合约部署
  const nftAuctionProxy = await upgrades.deployProxy(NftAuction, [], {
    initializer: "initialize"
  });

  // 等待部署完成
  await nftAuctionProxy.waitForDeployment();

  const proxyAddress = await nftAuctionProxy.getAddress();
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress)
  console.log("代理合约地址:", proxyAddress);
  console.log("逻辑合约地址:", implAddress);

  // 保存合约地址和ABI 
  const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
  // 输出到文件
  fs.writeFileSync(
    storePath,
    JSON.stringify({
      proxyAddress,
      implAddress,
      abi: NftAuction.interface.format("json"),
    })
  );
  // 保存合约地址和ABI 到 hardhat-deploy 的部署记录中，供测试使用
  await save("NftAuctionProxy", {
    abi: NftAuction.interface.format("json"),
    address: proxyAddress,
    args: [],
    log: true,
  });

  // const nftAuction = await deploy("NFTAuction", {
  //   from: deployer,
  //   args: [],
  //   log: true,
  // });
  // console.log("NFT Auction deployed to:", nftAuction.address);
}
// 导出后供测试使用
module.exports.tags = ["deployNftAuction"];