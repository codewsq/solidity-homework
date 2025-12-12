// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC721} from "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./IERC165.sol";
import "./String.sol";

contract MyERC721 is IERC721, IERC721Metadata {
    using Strings for uint256;

    // key-所属人 value - NFT数量
    mapping(address owner => uint256) private _balances;

    // key-tokenId value-所属人
    mapping(uint256 tokenId => address) private _owners;

    // key-tokenId value-被授权人-消费者
    mapping(uint256 tokenId => address) private _tokenApprovals;

    // 批量授权 key-所属人 value-（key-消费者 value-是否批量授权）
    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;


    // token name
    string private _name;

    // Token symbol
    string private _symbol;

    // 错误 无效的接收者
    error ERC721InvalidReceiver(address receiver);


    constructor(string memory name_,string memory symbol_){
        _name = name_;
        _symbol = symbol_;
    }

     // 实现IERC165接口supportsInterface
    function supportsInterface(bytes4 interfaceId)external pure override returns (bool){
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function name() external view returns (string memory){
        return _name;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory){
        require(_owners[tokenId] != address(0), "Token Not Exist");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

     /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance){
         if (owner == address(0)) {
            revert ("owner not is 0x00");
        }
        return _balances[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner){
        return _owners[tokenId];
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{
        // 校验是否授权
        require(_tokenApprovals[tokenId] == msg.sender,"not approval");
        require(to != address(0),"to not is 0x00");
        require(from != address(0),"from not is 0x00");
         _transfer(from, to, tokenId);
         _checkOnERC721Received(from,to,tokenId,data);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external{
            // 校验是否授权
        require(_tokenApprovals[tokenId] == msg.sender,"not approval");
        require(to != address(0),"to not is 0x00");
        require(from != address(0),"from not is 0x00");
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from,to,tokenId,"");
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external{
        // 校验是否授权
        require(_tokenApprovals[tokenId] == msg.sender,"not approval");
        require(to != address(0),"to not is 0x00");
        require(from != address(0),"from not is 0x00");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal {
        // 修改 用户NFT数量
        _balances[from] -= 1;
        _balances[to] += 1;
        // 更新NFT所属人
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external{
        require(_owners[tokenId] == msg.sender,"tokenId not is owner");
        emit Approval(msg.sender, to, tokenId);
        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external{
        require(operator != address(0),"operator not is 0x00");
        require(msg.sender != address(0),"owner not is 0x00");
        _operatorApprovals[msg.sender][operator] = approved;
    }


    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator){
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool){
        return _operatorApprovals[owner][operator];
    }

    function _mint(address to, uint256 tokenId) internal {
        if(to == address(0)){
            revert ("to not is 0x00");
        }
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _saleMint(address to,uint256 tokenId) internal {
        _mint(to,tokenId);
        _checkOnERC721Received(msg.sender,to,tokenId,"");
    }

    function saleMint(address to,uint256 tokenId) external {
        _saleMint(to,tokenId);
    }

    function burn(uint256 tokenId) external {
        address owner = _owners[tokenId];
        if(owner != msg.sender){
            revert ("tokenId not is owner");
        }
        _balances[owner] -= 1;
        _owners[tokenId] = address(0);
    }


    // _checkOnERC721Received：函数，用于在 to 为合约的时候调用IERC721Receiver-onERC721Received, 以防 tokenId 被不小心转入黑洞。
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}