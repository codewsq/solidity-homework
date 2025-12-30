const { ethers, deployments, upgrades } = require("hardhat");
const { expect } = require("chai");
// 部署后测试用
describe("NftAuction", function () {
  let signer, buyer;


  it("Should create an auction", async function () {
    [signer, buyer] = await ethers.getSigners();

    const TestERC721 = await ethers.getContractFactory("TestERC721");
    const testERC721 = await TestERC721.connect(signer).deploy("TestNFT", "TNFT");
    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    // 2. mint 10个 NFT 
    for (let i = 1; i <= 10; i++) {
      const tx = await testERC721.mint(signer.address, i); // mint 10个 NFT
      await tx.wait();
    }
    console.log("铸造 10 NFT 给部署者:", signer.address);
    console.log("---------------------------------------------");

    // 1.部署业务合约
    await deployments.fixture(["deployNftAuction"]);
    let nftAuctionProxy = await deployments.get("NftAuctionProxy");

    // 2.调用createAuction 方法创建拍卖
    const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);
    // 2.1授权拍卖合约可以操作这个 NFT
    const tokenId = 1;
    const approveTx = await testERC721.connect(signer).approve(nftAuctionProxy.address, tokenId);
    await approveTx.wait();
    console.log(`授权拍卖合约 ${nftAuctionProxy.address} 可以操作 NFT ID: ${tokenId}`);
    // 2.2创建拍卖
    await nftAuction.createdAuction(ethers.parseEther("1"), 100 * 1000, testERC721Address, tokenId);
    const auction = await nftAuction.auctions(0);
    console.log("创建拍卖成功：", auction);
    // 获取升级合约之前的业务合约地址
    const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
    console.log("升级前的逻辑合约地址：", implAddress1);
    // 3.升级合约
    await deployments.fixture(["upgradeNftAuction"]);
    // 获取升级合约之后的业务合约地址
    const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
    console.log("升级后的逻辑合约地址：", implAddress2);
    console.log("---------------------------------------------");
    // 4.读取合约的auction[0]
    const NftAuctionV2 = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);
    console.log("升级后读取拍卖信息：", await NftAuctionV2.auctions(0));
    const auction2 = await NftAuctionV2.getAuctionDetails(0);
    console.log("通过新方法获取拍卖信息：", auction2);
    // 断言升级前后数据一致，且逻辑合约地址不同

    expect(auction2.startTime).to.equal(auction.startTime);
    expect(implAddress1).to.not.equal(implAddress2);

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