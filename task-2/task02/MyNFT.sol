// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract MyNFT is ERC721, ERC721URIStorage, Ownable{
    // 私有变量，记录下一个可用的tokenId
    // uint256是256位无符号整数，Solidity中常用类型
    uint256 private _nextTokenId;

     /** bafybeigljl4zfpkwwotajerstx3da7camlr32n2znfpqnx25h2weglw26e
     * @dev 构造函数，在合约部署时执行一次
     * @param initialOwner 设置合约的初始所有者地址
     * 
     * 功能：
     * 1. 调用父合约ERC721的构造函数，设置NFT名称和符号
     * 2. 调用父合约Ownable的构造函数，设置合约所有者
     */
    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    /**
     * @dev 安全的铸造函数（内部使用）
     * @param to NFT接收者的地址
     * @param uri NFT元数据的IPFS URI
     * 
     * 特点：
     * 1. 使用onlyOwner修饰符，只有合约所有者可以调用
     * 2. 使用_safeMint而不是_mint，会检查接收地址是否为合约，如果是则必须实现ERC721接收接口
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        // 获取当前tokenId，然后自增_nextTokenId
        uint256 tokenId = _nextTokenId++;

        // 调用ERC721的_safeMint函数铸造NFT
        // 参数：接收者地址，tokenId
        _safeMint(to, tokenId);

        // 调用ERC721URIStorage的_setTokenURI函数设置元数据URI
        // 参数：tokenId，元数据URI
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev 公开的铸造函数，包装了safeMint
     * @param recipient NFT接收者的地址
     * @param _tokenURI NFT元数据的IPFS URI
     * 
     * 注意：这个函数实际上和safeMint功能相同
     * 通常我们会保留这样的包装函数，以提供更直观的接口名称
     */
    function mintNFT(address recipient, string memory _tokenURI) public onlyOwner {
        safeMint(recipient, _tokenURI);
    }

    /**
     * @dev 重写tokenURI函数
     * @param tokenId 要查询的NFT的ID
     * @return string memory 返回该NFT的元数据URI
     * 
     * 为什么需要重写？
     * 因为同时继承了ERC721和ERC721URIStorage，两者都有tokenURI函数
     * 需要明确指定使用哪个父合约的函数
     * override(ERC721, ERC721URIStorage) 表示重写这两个父合约的函数
     */
    function tokenURI(uint256 tokenId)public view override(ERC721, ERC721URIStorage) returns (string memory){
        // 调用ERC721URIStorage的tokenURI函数
        // 因为ERC721URIStorage提供了存储和返回URI的功能
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 重写supportsInterface函数
     * @param interfaceId 接口ID（遵循ERC165标准）
     * @return bool 如果合约支持该接口则返回true
     * 
     * ERC165标准：允许合约声明它们实现了哪些接口
     * 这对于像OpenSea这样的市场很重要，它们需要知道合约支持哪些功能
     * override(ERC721, ERC721URIStorage) 重写ERC721和ERC721URIStorage的supportsInterface函数
     */
    function supportsInterface(bytes4 interfaceId)public view override(ERC721, ERC721URIStorage) returns (bool){
        // 调用父合约的supportsInterface函数
        return super.supportsInterface(interfaceId);
    }
}