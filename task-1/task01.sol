// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/*
1.创建一个名为Voting的合约，包含以下功能：
一个mapping来存储候选人的得票数
一个vote函数，允许用户投票给某个候选人
一个getVotes函数，返回某个候选人的得票数
一个resetVotes函数，重置所有候选人的得票数
*/
contract Voting{
    // 保存候选人选票数: key-候选人  value-票数
    mapping(address => uint256) public votMapping;
    address[] public keyList;

    // 控制用户只能投一票
    mapping(address => bool) public votVaildMapping;
    // 投票人列表
    address[] public voterList;


    // 投票给候选人， candidate - 候选人地址
    function vote(address candidate) public {
        // 校验不能给自己投票
        require(msg.sender != candidate,"operator not is candidate");
        // 校验投票人是否未投过票
        require(!votVaildMapping[msg.sender],"The msg.sender has already cast a vote");

        if (votMapping[candidate] == 0){
            keyList.push(candidate);
        }
        votMapping[candidate] += 1;

        votVaildMapping[msg.sender] = true;
        voterList.push(msg.sender);
    }

    // 返回某个候选人得票数， candidate - 候选人地址
    function getVotes(address candidate) public view returns (uint256){
        return votMapping[candidate];
    }

    // 重置所有候选人的得票数
    function resetVotes() public {
        for (uint i = 0; i < keyList.length; i++) {
            votMapping[keyList[i]] = 0;
        }

        for (uint i = 0; i < voterList.length; i++) {
            delete votVaildMapping[voterList[i]];
        }
    }

}