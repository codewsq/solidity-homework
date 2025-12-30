const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Test Auction", function () {
  it("Should deploy TestERC721 and create an auction", async function () {
    await main();
  });
});


async function main() {
  await deployments.fixture("deployNftAuction");
  const nftAuctionProxy = await deployments.get("NftAuctionProxy");

  const [signer, buyer] = await ethers.getSigners();

  // 打印signer和buyer的余额
  const signerBalance = await ethers.provider.getBalance(signer.address);
  const buyerBalance = await ethers.provider.getBalance(buyer.address);
  console.log("部署者余额:", ethers.formatEther(signerBalance), "ETH");
  console.log("买家余额:", ethers.formatEther(buyerBalance), "ETH");

  // 1.部署 ERC721 测试合约
  const TestERC721 = await ethers.getContractFactory("TestERC721");
  const testERC721 = await TestERC721.connect(signer).deploy("TestNFT", "TNFT");
  await testERC721.waitForDeployment();
  const testERC721Address = await testERC721.getAddress();
  console.log("测试 ERC721 合约地址：", testERC721Address);
  console.log("---------------------------------------------");

  // 2. mint 10个 NFT 
  for (let i = 1; i <= 10; i++) {
    const tx = await testERC721.mint(signer.address, i); // mint 10个 NFT
    await tx.wait();
  }
  console.log("铸造 10 NFT 给部署者:", signer.address);
  console.log("---------------------------------------------");


  const tokenId = 1;
  // 3. 调用 createAuction 创建拍卖
  const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);
  // 3.1授权拍卖合约可以操作这个 NFT
  const approveTx = await testERC721.connect(signer).approve(nftAuctionProxy.address, tokenId);
  await approveTx.wait();
  console.log(`授权拍卖合约 ${nftAuctionProxy.address} 可以操作 NFT ID: ${tokenId}`);
  console.log("---------------------------------------------");

  // 3.2创建拍卖
  const startingPrice = ethers.parseEther("0.01");
  const duration = 5 * 60 * 1000; // 5分钟
  const createAuctionTx = await nftAuction.connect(signer).createdAuction(
    startingPrice,
    duration,
    testERC721Address,
    tokenId
  );
  await createAuctionTx.wait();
  console.log(`创建拍卖成功,NFT 地址: ${testERC721Address}, Token ID: ${tokenId}`);
  console.log("---------------------------------------------");


  // 4. 出价
  const bidAmount = ethers.parseEther("0.02");
  const bidTx = await nftAuction.connect(buyer).placeBid(0, { value: bidAmount });
  await bidTx.wait();
  console.log(`买家 ${buyer.address} 出价成功，出价金额: ${ethers.formatEther(bidAmount)} ETH`);
  console.log("---------------------------------------------");


  // 5. 结束拍卖
  // 模拟时间流逝
  console.log("等待拍卖结束...");
  await time.increaseTo(await time.latest() + duration + 20 * 1000);
  console.log("等待结束，准备结束拍卖");
  // 快进时间到拍卖结束

  // 结束拍卖
  const endAuctionTx = await nftAuction.endAuction(0);
  await endAuctionTx.wait();
  console.log("拍卖已结束");
  console.log("---------------------------------------------");

  // 6. 验证结果
  const auction = await nftAuction.auctions(0);
  console.log("拍卖详情:", auction);
  expect(auction.highestBidder).to.equal(buyer.address); // 最高出价人
  expect(auction.highestBid).to.equal(bidAmount); // 最高出价

  // 验证 NFT 所有权转移给最高出价人
  const newOwner = await testERC721.ownerOf(tokenId);
  console.log("NFT 新拥有者地址:", newOwner);
  expect(newOwner).to.equal(buyer.address); // 验证 NFT 所有权转移给最高出价人

  // 打印signer和buyer的余额
  const signerBalanceNew = await ethers.provider.getBalance(signer.address);
  const buyerBalanceNew = await ethers.provider.getBalance(buyer.address);
  console.log("部署者余额:", ethers.formatEther(signerBalanceNew), "ETH");
  console.log("买家余额:", ethers.formatEther(buyerBalanceNew), "ETH");
}
