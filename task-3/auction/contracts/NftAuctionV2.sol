// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// 导入IERC721.sol
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// 导入IERC20.sol
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 导入Chainlink价格预言机接口
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract NftAuctionV2 is Initializable, UUPSUpgradeable, IERC721Receiver {
    struct Auction {
        address payable seller; // 售卖人
        uint256 startingPrice; // 起拍价格（USD价值，18位小数）
        uint256 duration; // 截至时间
        uint256 startTime; // 开始时间
        uint256 endTime; // 结束时间
        uint256 highestBid; // 最高价格 -- 已废弃，合约升级后不再使用
        address payable highestBidder; // 最高出价者
        bool ended; // 是否结束
        address nftAddress; // NFT contract address
        uint256 tokenId; // NFT ID
        // 参与竞价的资产类型 0x 地址表示eth，其他地址表示erc20
        // 0x0000000000000000000000000000000000000000 表示eth
        address tokenAddress; // 当前最高出价的代币地址
        bool isEth; // 是否是ETH出价（新增）
        uint256 highestBidValue; // 最高出价的USD价值（18位小数）
        uint256 highestBidAmount; // 最高出价的代币数量（实际数量）
    }

    // 状态变量
    mapping(uint256 nextAuctionId => Auction) public auctions;
    // 下一个拍卖ID
    uint256 public nextAuctionId;
    // 总拍卖数
    uint256 public auctionCount;
    address private admin; // 管理员地址

    // 价格预言机接口
    mapping(address => AggregatorV3Interface) public priceFeeds; // 价格预言机地址
    // 代币精度缓存（避免每次调用decimals()）
    mapping(address => uint8) public tokenDecimals; // 代币精度缓存

    event AuctionCreated(
        address indexed seller,
        uint256 indexed auctionId,
        uint256 startingPrice,
        uint256 duration,
        uint256 startTime,
        uint256 endTime,
        address nftAddress,
        uint256 tokenId
    ); // 拍卖创建事件

    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 usdValue
    ); // 新出价事件

    function initialize() public initializer {
        admin = msg.sender;
        // ETH的精度设置为18
        tokenDecimals[address(0)] = 18;
    }

    // 设置价格预言机地址和代币精度
    function setAggregator(
        address _tokenAddress,
        address _aggregator,
        uint8 _decimals
    ) public {
        require(msg.sender == admin, "Only admin can set aggregator");
        priceFeeds[_tokenAddress] = AggregatorV3Interface(_aggregator);
        tokenDecimals[_tokenAddress] = _decimals;
    }
    // 设置代币精度（单独设置）
    function setTokenDecimals(address _tokenAddress, uint8 _decimals) public {
        require(msg.sender == admin, "Only admin can set token decimals");
        tokenDecimals[_tokenAddress] = _decimals;
    }

    // 获取最新价格
    // ETH -> USD -> 297859595700 -> 2978.59595700
    // USDC -> USD -> 99966727 -> 0.99966727
    function getChainlinkDataFeedLatestAnswer(
        address _tokenAddress
    ) public view returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[_tokenAddress];
        require(
            address(priceFeed) != address(0),
            "Price feed not set for token"
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer; // 返回最新价格
    }

    // 计算USD价值（18位小数）
    function calculateUSDValue(
        address _tokenAddress,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        // 获取代币精度
        uint8 decimals = tokenDecimals[_tokenAddress];
        require(decimals > 0, "Token decimals not set");

        // 获取价格（8位小数）
        int256 price = getChainlinkDataFeedLatestAnswer(_tokenAddress);
        require(price > 0, "Invalid price");

        // 计算USD价值
        // 公式: (tokenAmount * price) / 10^(8+decimals-18) * 10^18
        // 简化: (tokenAmount * price) * 10^(18-decimals) / 10^8

        if (decimals <= 18) {
            // 需要补充精度到18位
            uint256 factor = 10 ** (18 - decimals);
            return (_tokenAmount * uint256(price) * factor) / 1e8;
        } else {
            // 精度超过18位，需要减少精度
            uint256 factor = 10 ** (decimals - 18);
            return (_tokenAmount * uint256(price)) / (1e8 * factor);
        }
    }

    function createdAuction(
        uint256 _startingPriceUSD, // USD价值（18位小数）
        uint256 _duration,
        address _nftAddress,
        uint256 _tokenId
    ) public {
        require(msg.sender == admin, "Only admin can create auction");
        // 检查拍卖是否有效
        require(_startingPriceUSD > 0, "Starting price must be greater than 0");
        // require(_duration > 1000 * 60, "Duration must be greater than 0");
        require(_nftAddress != address(0), "NFT address must be valid");

        // 将tokenId转给当前合约
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // 创建拍卖
        auctions[nextAuctionId] = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPriceUSD,
            duration: _duration,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            highestBid: 0, // 已废弃，合约升级后不再使用
            highestBidder: payable(address(0)),
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenAddress: address(0), // 默认地址0
            isEth: false, // 默认不是ETH出价
            highestBidValue: _startingPriceUSD,
            highestBidAmount: 0
        });
        // 触发事件
        emit AuctionCreated(
            msg.sender,
            nextAuctionId,
            _startingPriceUSD,
            _duration,
            block.timestamp,
            block.timestamp + _duration,
            _nftAddress,
            _tokenId
        );
        // 增加拍卖计数
        auctionCount++;
        // 增加下一个拍卖ID
        nextAuctionId++;
    }

    // 出价
    function placeBid(
        uint256 _auctionId,
        address _tokenAddress,
        uint256 _amount
    ) public payable {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "Auction has ended");
        // 检查拍卖已经开始
        require(
            block.timestamp >= auction.startTime,
            "Auction has not started yet"
        );
        // 检查拍卖还未结束
        require(block.timestamp <= auction.endTime, "Auction has ended");

        // 获取实际出价金额
        uint256 bidAmount;
        if (_tokenAddress == address(0)) {
            // ETH出价
            bidAmount = msg.value;
        } else {
            // ERC20代币出价
            bidAmount = _amount;
            require(bidAmount > 0, "Bid amount must be greater than 0");

            // 转移代币到合约（需要提前授权给本合约）
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                bidAmount
            );
        }

        // 计算USD价值
        uint256 bidValue = calculateUSDValue(_tokenAddress, bidAmount);

        // 检查出价必须大于当前最高出价
        require(
            bidValue > auction.highestBidValue,
            "Bid must be higher than current highest bid"
        );

        // 如果有最高出价，退还给最高出价者
        if (auction.highestBidder != address(0)) {
            _refundPreviousBid(auction);
        }

        // 更新拍卖信息
        auction.highestBidValue = bidValue;
        auction.highestBidAmount = bidAmount;
        auction.highestBidder = payable(msg.sender);
        auction.tokenAddress = _tokenAddress;
        auction.isEth = (_tokenAddress == address(0));

        emit NewBid(_auctionId, msg.sender, _tokenAddress, bidAmount, bidValue);
    }

    // 退款给之前的出价者
    function _refundPreviousBid(Auction storage auction) internal {
        if (auction.isEth) {
            // ETH退款
            (bool success, ) = auction.highestBidder.call{
                value: auction.highestBidAmount
            }("");
            require(success, "Failed to refund ETH");
        } else {
            // ERC20代币退款
            IERC20(auction.tokenAddress).transfer(
                auction.highestBidder,
                auction.highestBidAmount
            );
        }
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        // 检查拍卖是否已经结束
        require(!auction.ended, "Auction has already ended");
        // 检查拍卖是否已经结束
        require(
            block.timestamp >= auction.endTime,
            "Auction has not ended yet"
        );
        // 检查拍卖是否有人出价
        require(auction.highestBidder != address(0), "No bids placed");

        // 将NFT转给最高出价者
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId
        );

        // 将拍卖收益发送给卖家
        _transferToSeller(auction);

        // 将拍卖标记为已结束
        auction.ended = true;
    }
    // 转账给卖家
    function _transferToSeller(Auction storage auction) internal {
        if (auction.isEth) {
            // 支付ETH给卖家
            (bool success, ) = auction.seller.call{
                value: auction.highestBidAmount
            }("");
            require(success, "Failed to send ETH to seller");
        } else {
            // 支付ERC20代币给卖家
            IERC20(auction.tokenAddress).transfer(
                auction.seller,
                auction.highestBidAmount
            );
        }
    }

    // 紧急取消拍卖（仅管理员）
    function emergencyCancel(uint256 _auctionId) public {
        require(msg.sender == admin, "Only admin can cancel auction");
        Auction storage auction = auctions[_auctionId];

        require(!auction.ended, "Auction already ended");

        // 如果有出价，退款
        if (auction.highestBidder != address(0)) {
            _refundPreviousBid(auction);
        }

        // 将NFT退回给卖家
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        auction.ended = true;
    }

    // 获取拍卖数量
    function getAuctionCount() public view returns (uint256) {
        return auctionCount;
    }

    // 获取拍卖详情 V2
    function getAuctionDetails(
        uint256 _auctionId
    ) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

    // 获取当前拍卖的USD价值（方便前端显示）
    function getCurrentPriceUSD(
        uint256 _auctionId
    ) public view returns (uint256) {
        return auctions[_auctionId].highestBidValue;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade contract");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // 接收ETH的回退函数
    receive() external payable {}
}
