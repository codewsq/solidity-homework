const { ethers, deployments, upgrades } = require("hardhat");
const { expect } = require("chai");
// 部署后测试用
describe("NftAuction", function () {

  it("Should create an auction", async function () {
    // 1.部署业务合约
    await deployments.fixture(["deployNftAuction"]);
    const nftAuctionProxy = await deployments.get("NftAuctionProxy");

    // 2.调用createAuction 方法创建拍卖
    const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);

    await nftAuction.createdAuction(ethers.parseEther("0.01"), 100 * 1000, ethers.ZeroAddress, 1);
    const auction = await nftAuction.auctions(0);
    console.log("创建拍卖成功：", auction);
    // 获取升级合约之前的业务合约地址
    const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
    // 3.升级合约
    await deployments.fixture(["upgradeNftAuction"]);
    // 获取升级合约之后的业务合约地址
    const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);

    // 4.读取合约的auction[0]
    const auction2 = await nftAuction.auctions(0);
    console.log("升级后读取拍卖：", auction2)

    const NftAuctionV2 = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);
    console.log("升级后的新函数：", await NftAuctionV2.getAuction(0))

    expect(auction2.startTime).to.equal(auction.startTime);
    expect(implAddress1).to.not.equal(auction.duration);

    // const NftAuction = await ethers.getContractFactory("NftAuction");
    // const nftAuction = await NftAuction.deploy();
    // await nftAuction.waitForDeployment();

    // // 创建拍卖 uint256 _startingPrice,uint256 _duration,address _nftAddress,uint256 _tokenId
    // await nftAuction.createdAuction(ethers.parseEther("0.000000000000000001"), 100 * 1000, ethers.ZeroAddress, 1);

    // // 获取拍卖
    // const auction = await nftAuction.auctions(0);
    // console.log(auction);
    // const NFT = await ethers.getContractFactory("NFT");
  })
});