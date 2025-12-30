// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// 导入IERC721.sol
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NftAuction is Initializable, UUPSUpgradeable, IERC721Receiver {
    struct Auction {
        address payable seller; // 售卖人
        uint256 startingPrice; // 起拍价格
        uint256 duration; // 截至时间
        uint256 startTime; // 开始时间
        uint256 endTime; // 结束时间
        uint256 highestBid; // 最高价格
        address payable highestBidder; // 最高出价者
        bool ended; // 是否结束
        address nftAddress; // NFT contract address
        uint256 tokenId; // NFT ID
    }

    // 状态变量
    mapping(uint256 nextAuctionId => Auction) public auctions;
    // 下一个拍卖ID
    uint256 public nextAuctionId;
    // 总拍卖数
    uint256 public auctionCount;
    address private admin; // 管理员地址

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

    function initialize() public initializer {
        admin = msg.sender;
    }

    function createdAuction(
        uint256 _startingPrice,
        uint256 _duration,
        address _nftAddress,
        uint256 _tokenId
    ) public {
        require(msg.sender == admin, "Only admin can create auction");
        // 检查拍卖是否有效
        require(_startingPrice > 0, "Starting price must be greater than 0");
        // require(_duration > 1000 * 60, "Duration must be greater than 0");
        require(_nftAddress != address(0), "NFT address must be valid");

        // 授权给当前合约
        // IERC721(_nftAddress).approve(address(this), _tokenId);
        // 将tokenId转给当前合约
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // 创建拍卖
        auctions[nextAuctionId] = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            duration: _duration,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            highestBid: _startingPrice,
            highestBidder: payable(address(0)),
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId
        });
        // 触发事件
        emit AuctionCreated(
            msg.sender,
            nextAuctionId,
            _startingPrice,
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
    function placeBid(uint256 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];
        // 检查拍卖已经开始
        require(
            block.timestamp >= auction.startTime,
            "Auction has not started yet"
        );
        // 检查拍卖还未结束
        require(
            block.timestamp <= auction.startTime + auction.duration,
            "Auction has ended"
        );
        // 检查出价必须大于最高出价
        require(
            msg.value > auction.highestBid,
            "Bid must be higher than current highest bid"
        );
        // 如果有最高出价，退还给最高出价者
        if (auction.highestBidder != address(0)) {
            (bool success, ) = auction.highestBidder.call{
                value: auction.highestBid
            }("");
            require(success, "Failed to send refund to highest bidder");
        }
        // 更新最高出价和最高出价者
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        // 检查拍卖是否已经结束
        require(
            block.timestamp >= auction.startTime + auction.duration,
            "Auction has not ended yet"
        );
        // 检查拍卖是否已经结束
        require(!auction.ended, "Auction has already ended");
        // 检查拍卖是否有人出价
        require(auction.highestBidder != address(0), "No bids placed");
        // 将NFT转给最高出价者
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId
        );
        // 将拍卖标记为已结束
        auction.ended = true;
        // 将拍卖价格发送给卖家
        (bool success, ) = auction.seller.call{value: auction.highestBid}("");
        require(success, "Failed to send payment to seller");
    }

    // 获取拍卖数量
    function getAuctionCount() public view returns (uint256) {
        return auctionCount;
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
}
