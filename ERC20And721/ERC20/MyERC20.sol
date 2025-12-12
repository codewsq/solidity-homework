// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC20} from "./IERC20.sol";

contract MyERC20 is IERC20 {

    // key：币所属 value：币数量
    mapping(address=>uint256) public _balace;
    // 授权币记录  key-币所属者 value-（key-消费者 value-授权币数量）
    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalsupply; // 总铸造代币

    string public _name; // 币名称
    string public _symbol; // 币符号

    constructor(string memory name_,string memory symbol_){
        name_ = _name;
        symbol_ = _symbol;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev 返回合约生成的代币的总数。
     */
    function totalSupply() external view  returns (uint256){
        return _totalsupply;
    }

    /**
     * @dev 返回account拥有的代币数
     */
    function balanceOf(address account) external view returns (uint256){
        return _balace[account];
    }

    /**
     * @dev 从调用者的帐户中移动一个‘ value ’数量的令牌到‘ to ’。
     * 返回一个布尔值，指示操作是否成功。
     * 发出一个{Transfer}事件。
     */
    function transfer(address to, uint256 value) external returns (bool){
        require(value > 0, "value not zero");
        require(_balace[msg.sender] > value,"owner Not enough value!");
        require(to != address(0),"to not is 0x00");
        _transfer(msg.sender,to,value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev 返回‘ sender ’的剩余token数
     * 允许代表“所有者”通过{transferFrom}进行支出。这是默认为零。
     * 该值在调用{approve}或{transferFrom}时改变。
     */
    function allowance(address owner, address spender) external view returns (uint256){
        return _allowances[owner][spender];
    }

    /**
     * @dev 设置一个‘ value ’的token数量作为‘ sender ’的允许值
     *来电令牌。
     *返回一个布尔值，指示操作是否成功。
     *重要：注意，用这种方法改变一个津贴会带来风险
      有人可能会不幸地同时使用新旧津贴
     *交易排序。缓解这场竞争的一个可能的解决方案 条件是首先将支出者的津贴减少到0，并设置
     *之后的期望值：
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool){
        require(value > 0, "value not zero");
        require(spender != address(0),"spender not is 0x00!");
        require(_balace[msg.sender] > value,"owner Not enough value!");
        _allowances[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev 授权转账
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool){
        require(value > 0, "value not zero");
        require(_balace[from] > value,"owner Not enough value!");
        require(to != address(0),"to not is 0x00");
        require(_allowances[from][msg.sender] > value,"allowances Not enough value!");
        _transfer(from,to,value);
         _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }


    function _transfer(address from,address to,uint256 value) internal {
        _balace[from] -= value;
        _balace[to] += value;
    }

}