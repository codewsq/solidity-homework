// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/*
作业 1：ERC20 代币
任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
合约包含以下标准 ERC20 功能：
balanceOf：查询账户余额。
transfer：转账。
approve 和 transferFrom：授权和代扣转账。
使用 event 记录转账和授权操作。
提供 mint 函数，允许合约所有者增发代币。
提示：
使用 mapping 存储账户余额和授权信息。
使用 event 定义 Transfer 和 Approval 事件。
部署到sepolia 测试网，导入到自己的钱包
*/
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract WSQERC20 is IERC20{

    // 代币存储，key-币所属地址 value-代币数量
    mapping(address=>uint256) public balance;
    // 代币授权， key-币所属地址 value-(key-被授权者 value-授权数量)
    mapping(address=>mapping(address=>uint256)) private _allowance;

    uint256 public totalSupply = 0; // 代币总供给

    string public name;   // 名称
    string public symbol;  // 符号

    constructor(string memory _name,string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }


    // 返回指定账户的余额
    function balanceOf(address account) external view override returns (uint256){
        return balance[account];
    }

    // 转账
    function transfer(address to, uint256 value) external override returns (bool){
        // 校验 代币是否足够
        require(balance[msg.sender] >= value,"Insufficient balance");
        balance[msg.sender] -= value;
        balance[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

        // 授权
    function approve(address spender, uint256 value) external override returns (bool){
        // 校验 代币是否足够
        require(balance[msg.sender] >= value,"Insufficient balance");
        // 校验 接受消费者不为空
        require(spender != address(0),"spender not is 0x00");
        // 授权
        _allowance[msg.sender][spender] = value;
        // 事件
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // 授权转账
    function transferFrom(address from, address to, uint256 value) external override returns (bool){
        // 校验 所属者的代币是否足够
        require(balance[from] >= value,"Insufficient balance");
        // 校验 是否授权足够的代币
        require(_allowance[from][msg.sender] >= value,"Insufficient balance");
        // 交易
        _allowance[from][msg.sender] -= value;
        balance[from] -= value;
        balance[to] += value;
        // 事件
        emit Transfer(from, to, value);
        return true;
    }

    // 返回代币所属者授权给消费者的代币剩余数
    function allowance(address owner, address spender) external view returns (uint256){
        return _allowance[owner][spender];
    }

    // 铸币
    function mint(uint256 amount) external  {
        balance[msg.sender] += amount;
        totalSupply += amount;
        // 事件触发。 铸币交易时，转出地址是0x00
        emit Transfer(address(0), msg.sender, amount);
    }

}
