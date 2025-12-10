// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/*
编写合约
创建一个名为 BeggingContract 的合约。
合约应包含以下功能：
一个 mapping 来记录每个捐赠者的捐赠金额。
一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
一个 withdraw 函数，允许合约所有者提取所有资金。
一个 getDonation 函数，允许查询某个地址的捐赠金额。
使用 payable 修饰符和 address.transfer 实现支付和提款。
*/
contract BeggingContract{
    // 事件记录
    event Received(address sender, uint256 amount);
    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    // mapping 来记录每个捐赠者的捐赠金额。
    mapping(address => uint256) public balance;
    address public owner;

    constructor(){
        // 默认合约所有者为 合约部署人
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender,"not owner");
        _;
    }

    // receive() - 专门用于接收纯ETH转账（无数据）
    receive() external payable {
        donate();
        emit Received(msg.sender, msg.value);
    }

    // donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        // 记录捐赠者和捐赠金额
        balance[msg.sender] = msg.value;
        // 合约接受ETH 时应该不用显示编写这个代码
        // payable(address(this)).transfer(msg.value);
        // 事件
         emit Donated(msg.sender, msg.value);
    }
    

    // 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
    function withdraw() public payable onlyOwner{
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No funds to withdraw");
        payable(owner).transfer(_balance);
        emit Withdrawn(owner, _balance);
    }

    // getDonation 函数，允许查询某个地址的捐赠金额。
    function getDonation(address _donor) public view returns (uint256){
        return balance[_donor];
    }

}