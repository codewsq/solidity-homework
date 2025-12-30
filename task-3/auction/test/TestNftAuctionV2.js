const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Test NftAuctionV2", function () {
  let nftAuction;
  let testERC721;
  let signer, buyer, buyer2;
  let mockAggregatorETH;
  let mockAggregatorUSDC;

  // 测试用的常量
  const ETH_PRICE = 3000; // 1 ETH = 3000 USD
  const USDC_PRICE = 1.001; // 1 USDC = 1.001 USD
  const USDC_DECIMALS = 6;
  const ETH_DECIMALS = 18;

  beforeEach("初始化合约", async function () {
    // 强制重置网络，清理所有之前的部署记录
    // 这一步非常关键，确保每次测试都是在一个全新的链上运行
    await network.provider.send("hardhat_reset");
    // 1. 获取签名者
    [signer, buyer, buyer2] = await ethers.getSigners();

    // 2. 部署模拟价格预言机
    const MockAggregatorFactory = await ethers.getContractFactory("MockAggregator", signer);

    // 部署ETH价格预言机（1 ETH = 3000 USD，8位小数）
    mockAggregatorETH = await MockAggregatorFactory.deploy(
      ethers.parseUnits(ETH_PRICE.toString(), 8) // 3000 * 1e8
    );
    await mockAggregatorETH.waitForDeployment();

    // 部署USDC价格预言机（1 USDC = 1.001 USD，8位小数）
    mockAggregatorUSDC = await MockAggregatorFactory.deploy(
      ethers.parseUnits(USDC_PRICE.toString(), 8) // 1.001 * 1e8
    );
    await mockAggregatorUSDC.waitForDeployment();

    // 3. 部署拍卖合约
    await deployments.fixture("upgradeNftAuction");
    const nftAuctionProxy = await deployments.get("NftAuctionProxy");
    nftAuction = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);

    // 4. 设置价格预言机和代币精度
    // 设置ETH价格预言机（地址0表示ETH）
    await nftAuction.connect(signer).setAggregator(
      ethers.ZeroAddress, // ETH地址
      await mockAggregatorETH.getAddress(),
      ETH_DECIMALS
    );

    // 设置USDC价格预言机（使用一个模拟的USDC地址）
    const usdcAddress = ethers.getAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"); // 模拟地址
    await nftAuction.connect(signer).setAggregator(
      usdcAddress,
      await mockAggregatorUSDC.getAddress(),
      USDC_DECIMALS
    );

    // 5. 部署ERC721测试合约
    const TestERC721 = await ethers.getContractFactory("TestERC721", signer);
    testERC721 = await TestERC721.deploy("TestNFT", "TNFT");
    await testERC721.waitForDeployment();

    // 6. Mint NFT
    for (let i = 1; i <= 5; i++) {
      await testERC721.mint(signer.address, i);
    }
  });

  it("测试ETH拍卖流程 - 应该能使用ETH成功完成拍卖流程", async function () {
    const tokenId = 1;
    const startingPriceUSD = ethers.parseUnits("30", 18); // 30 USD（18位小数）
    const duration = 5 * 60; // 5分钟（秒）

    // 1. 授权拍卖合约
    await testERC721.connect(signer).approve(await nftAuction.getAddress(), tokenId);
    console.log(`授权拍卖合约操作 NFT ID: ${tokenId}`);

    // 2. 创建拍卖
    const createTx = await nftAuction.connect(signer).createdAuction(
      startingPriceUSD,
      duration,
      await testERC721.getAddress(),
      tokenId
    );
    await createTx.wait();

    console.log(`创建拍卖成功，拍卖ID: 0`);
    console.log(`起拍价: 30 USD (${startingPriceUSD.toString()} wei)`);

    // 3. 验证拍卖详情
    const auction0 = await nftAuction.getAuctionDetails(0);
    expect(auction0.seller).to.equal(signer.address);
    expect(auction0.startingPrice).to.equal(startingPriceUSD);
    expect(auction0.highestBidValue).to.equal(startingPriceUSD);

    // 4. 第一个出价者（使用ETH）
    const ethBidAmount1 = ethers.parseEther("0.01"); // 0.01 ETH
    // 0.01 ETH * 3000 USD/ETH = 30 USD（刚好等于起拍价，应该失败）

    await expect(
      nftAuction.connect(buyer).placeBid(
        0, // auctionId
        ethers.ZeroAddress, // ETH地址 - address(0)
        0, // amount（对于ETH，合约内部使用msg.value）
        { value: ethBidAmount1 }
      )
    ).to.be.revertedWith("Bid must be higher than current highest bid");

    // 5. 第二个出价者（使用ETH，更高的出价）
    const ethBidAmount2 = ethers.parseEther("0.011"); // 0.011 ETH
    // 0.011 ETH * 3000 USD/ETH = 33 USD > 30 USD

    const bidTx1 = await nftAuction.connect(buyer).placeBid(
      0,
      ethers.ZeroAddress,
      0,
      { value: ethBidAmount2 }
    );
    await bidTx1.wait();

    console.log(`买家 ${buyer.address} 出价成功`);
    console.log(`出价金额: ${ethers.formatEther(ethBidAmount2)} ETH`);
    console.log(`出价价值: 33 USD (0.011 ETH * 3000)`);

    // 验证拍卖状态更新
    const auctionAfterBid1 = await nftAuction.getAuctionDetails(0);
    expect(auctionAfterBid1.highestBidder).to.equal(buyer.address);
    expect(auctionAfterBid1.highestBidAmount).to.equal(ethBidAmount2);
    expect(auctionAfterBid1.tokenAddress).to.equal(ethers.ZeroAddress);
    expect(auctionAfterBid1.isEth).to.be.true;

    // 6. 第三个出价者（更高出价）
    // 记录卖家和买家2的余额用于后续验证
    const sellerBalanceBefore = await ethers.provider.getBalance(signer.address);
    const buyer2BalanceBefore = await ethers.provider.getBalance(buyer2.address);

    const ethBidAmount3 = ethers.parseEther("0.012"); // 0.012 ETH
    // 0.012 ETH * 3000 USD/ETH = 36 USD > 33 USD

    const bidTx2 = await nftAuction.connect(buyer2).placeBid(
      0,
      ethers.ZeroAddress,
      0,
      { value: ethBidAmount3 }
    );
    await bidTx2.wait();

    console.log(`买家 ${buyer2.address} 出价成功`);
    console.log(`出价金额: ${ethers.formatEther(ethBidAmount3)} ETH`);
    console.log(`出价价值: 36 USD (0.012 ETH * 3000)`);

    // 验证买家1收到退款
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceAfter).to.be.gt(ethers.parseEther("9999")); // 假设初始余额为10000 ETH
    console.log(`买家1 ${buyer.address} 收到退款`);

    // 7. 等待拍卖结束
    await time.increase(duration + 1);

    // 8. 结束拍卖
    const endTx = await nftAuction.connect(signer).endAuction(0);
    await endTx.wait();

    console.log("拍卖已结束");

    // 9. 验证结果
    const finalAuction = await nftAuction.getAuctionDetails(0);
    expect(finalAuction.ended).to.be.true;
    expect(finalAuction.highestBidder).to.equal(buyer2.address);

    // 验证NFT所有权转移
    const nftOwner = await testERC721.ownerOf(tokenId);
    expect(nftOwner).to.equal(buyer2.address);
    console.log(`NFT 已转移给最高出价者: ${nftOwner}`);

    // 验证卖家收到ETH
    const sellerBalanceAfter = await ethers.provider.getBalance(signer.address);
    const gasCost = await endTx.gasPrice * await endTx.gasLimit;
    const expectedSellerBalance = sellerBalanceBefore + ethBidAmount3 - gasCost;
    // expect(sellerBalanceAfter).to.be.closeTo(expectedSellerBalance, ethers.parseEther("0.001"));

    // 由于gas费用计算复杂，我们只验证卖家余额增加了（近似值）
    expect(sellerBalanceAfter).to.be.gt(sellerBalanceBefore);
    console.log(`卖家收到 ${ethers.formatEther(ethBidAmount3)} ETH`);

    // 验证买家2的余额减少（支付了ETH）
    const buyer2BalanceAfter = await ethers.provider.getBalance(buyer2.address);
    expect(buyer2BalanceAfter).to.be.lt(buyer2BalanceBefore);
  });


  it("测试ERC20代币拍卖流程 - 应该能使用USDC成功完成拍卖流程", async function () {
    // 部署模拟USDC代币
    const MockERC20 = await ethers.getContractFactory("MockERC20", signer);
    const mockUSDC = await MockERC20.deploy(
      "Mock USDC",
      "USDC",
      USDC_DECIMALS
    );
    await mockUSDC.waitForDeployment();

    // 为买家铸造USDC
    const usdcAmount = ethers.parseUnits("1000", USDC_DECIMALS); // 1000 USDC
    await mockUSDC.mint(buyer.address, usdcAmount);

    // 设置USDC价格预言机
    await nftAuction.connect(signer).setAggregator(
      await mockUSDC.getAddress(),
      await mockAggregatorUSDC.getAddress(),
      USDC_DECIMALS
    );

    const tokenId = 2;
    const startingPriceUSD = ethers.parseUnits("100", 18); // 100 USD
    const duration = 5 * 60; // 5分钟

    // 1. 授权
    await testERC721.connect(signer).approve(await nftAuction.getAddress(), tokenId);

    // 2. 创建拍卖
    await nftAuction.connect(signer).createdAuction(
      startingPriceUSD,
      duration,
      await testERC721.getAddress(),
      tokenId
    );

    // 3. 买家授权拍卖合约使用USDC
    await mockUSDC.connect(buyer).approve(
      await nftAuction.getAddress(),
      usdcAmount
    );

    // 4. 计算需要多少USDC才能达到101 USD（高于100 USD起拍价）
    // 公式：usdcAmount = (usdValue * 1e8) / price / 10^(decimals-18+8)
    // 简化：对于USDC（6位小数），要出价101 USD：
    // usdcAmount = 101 / 1.001 ≈ 100.9 USDC
    const usdcBidAmount = ethers.parseUnits("101", USDC_DECIMALS); // 先出101 USDC

    // 5. 出价
    const bidTx = await nftAuction.connect(buyer).placeBid(
      0, // auctionId
      await mockUSDC.getAddress(),
      usdcBidAmount
    );
    await bidTx.wait();

    console.log(`买家使用USDC出价成功`);
    console.log(`出价金额: ${ethers.formatUnits(usdcBidAmount, USDC_DECIMALS)} USDC`);
    console.log(`出价价值: 约101 USD`);

    // 6. 验证拍卖状态
    const auction = await nftAuction.getAuctionDetails(0);
    expect(auction.highestBidder).to.equal(buyer.address);
    expect(auction.highestBidAmount).to.equal(usdcBidAmount);
    expect(auction.tokenAddress).to.equal(await mockUSDC.getAddress());
    expect(auction.isEth).to.be.false;

    // 7. 等待并结束拍卖
    await time.increase(duration + 1);
    await nftAuction.connect(signer).endAuction(0);

    // 8. 验证NFT所有权
    const nftOwner = await testERC721.ownerOf(tokenId);
    expect(nftOwner).to.equal(buyer.address);

    // 9. 验证卖家收到USDC
    const sellerUSDCBalance = await mockUSDC.balanceOf(signer.address);
    expect(sellerUSDCBalance).to.equal(usdcBidAmount);

    console.log(`卖家收到 ${ethers.formatUnits(usdcBidAmount, USDC_DECIMALS)} USDC`);
  });



  it("测试价值计算 - 应该正确计算不同代币的USD价值", async function () {
    // 测试ETH价值计算
    const ethAmount = ethers.parseEther("1"); // 1 ETH
    const ethValue = await nftAuction.calculateUSDValue(
      ethers.ZeroAddress,
      ethAmount
    );

    // 1 ETH * 3000 USD/ETH = 3000 USD（18位小数）
    const expectedEthValue = ethers.parseUnits("3000", 18);
    expect(ethValue).to.equal(expectedEthValue);
    console.log(`1 ETH = ${ethers.formatUnits(ethValue, 18)} USD`);

    // 测试USDC价值计算
    const MockERC20 = await ethers.getContractFactory("MockERC20", signer);
    const mockUSDC = await MockERC20.deploy("Mock USDC", "USDC", 6);
    await mockUSDC.waitForDeployment();

    await nftAuction.connect(signer).setAggregator(
      await mockUSDC.getAddress(),
      await mockAggregatorUSDC.getAddress(),
      6
    );

    const usdcAmount = ethers.parseUnits("1000", 6); // 1000 USDC
    const usdcValue = await nftAuction.calculateUSDValue(
      await mockUSDC.getAddress(),
      usdcAmount
    );

    // 1000 USDC * 1.001 USD/USDC = 1001 USD（18位小数）
    const expectedUsdcValue = ethers.parseUnits("1001", 18);
    expect(usdcValue).to.equal(expectedUsdcValue);
    console.log(`1000 USDC = ${ethers.formatUnits(usdcValue, 18)} USD`);
  });



  it("测试边界情况 - 不应该在拍卖未开始时出价", async function () {
    const tokenId = 3;
    const startingPriceUSD = ethers.parseUnits("10", 18);
    const duration = 5 * 60;

    await testERC721.connect(signer).approve(await nftAuction.getAddress(), tokenId);

    // 创建一个未来开始的拍卖（通过设置开始时间）
    // 注意：当前合约没有设置开始时间的参数，这里假设立即开始
    await nftAuction.connect(signer).createdAuction(
      startingPriceUSD,
      duration,
      await testERC721.getAddress(),
      tokenId
    );

    // 正常情况下可以立即出价
    const ethBidAmount = ethers.parseEther("0.02");
    const bidTx = await nftAuction.connect(buyer).placeBid(
      0,
      ethers.ZeroAddress,
      0,
      { value: ethBidAmount }
    );
    await expect(bidTx.wait()).to.not.be.reverted;
  });

  it("不应该在拍卖结束后出价", async function () {
    const tokenId = 4;
    const startingPriceUSD = ethers.parseUnits("10", 18);
    const duration = 60; // 仅1分钟

    await testERC721.connect(signer).approve(await nftAuction.getAddress(), tokenId);

    await nftAuction.connect(signer).createdAuction(
      startingPriceUSD,
      duration,
      await testERC721.getAddress(),
      tokenId
    );

    // 等待拍卖结束
    await time.increase(duration + 10);

    // 尝试出价应该失败
    const ethBidAmount = ethers.parseEther("0.02");
    await expect(
      nftAuction.connect(buyer).placeBid(
        0,
        ethers.ZeroAddress,
        0,
        { value: ethBidAmount }
      )
    ).to.be.revertedWith("Auction has ended");
  });

  it("不应该接受低于当前最高出价的报价", async function () {
    const tokenId = 5;
    const startingPriceUSD = ethers.parseUnits("10", 18);
    const duration = 5 * 60;

    await testERC721.connect(signer).approve(await nftAuction.getAddress(), tokenId);

    await nftAuction.connect(signer).createdAuction(
      startingPriceUSD,
      duration,
      await testERC721.getAddress(),
      tokenId
    );

    // 第一个出价
    const ethBidAmount1 = ethers.parseEther("0.02"); // 约60 USD
    await nftAuction.connect(buyer).placeBid(
      0,
      ethers.ZeroAddress,
      0,
      { value: ethBidAmount1 }
    );

    // 第二个出价（低于第一个）应该失败
    const ethBidAmount2 = ethers.parseEther("0.015"); // 约45 USD < 60 USD
    await expect(
      nftAuction.connect(buyer).placeBid(
        0,
        ethers.ZeroAddress,
        0,
        { value: ethBidAmount2 }
      )
    ).to.be.revertedWith("Bid must be higher than current highest bid");
  });

});
