// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/*
2.反转字符串 (Reverse String)
题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
*/

contract reverseStr{


    function revertStr(string memory _str) public pure returns(string memory){
        // 将 string 转换为 bytes
        bytes memory strBytes = bytes(_str);
        // 创建新的 bytes 数组存储反转结果
        bytes memory newBytes = new bytes(strBytes.length);

        // 双指针反转
        for (uint i = 0; i < strBytes.length; i++) {
            newBytes[i] = strBytes[strBytes.length - 1 -i];
        }

        // 将 bytes 转换回 string
        return string(newBytes);
    }


}