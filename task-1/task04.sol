// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
4.用 solidity 实现罗马数字转数整数
*/
contract IntegerToRoman {
    // 主要函数：将整数转换为罗马数字
    function intToRoman(uint256 num) public pure returns (string memory) {
        // 检查输入范围（题目要求 1-3999）
        require(num >= 1 && num <= 3999, "Number must be between 1 and 3999");
        
        // 存储结果
        bytes memory result = new bytes(0);
        
        // 从大到小处理每个十进制位
        while (num > 0) {
            if (num >= 1000) {
                result = abi.encodePacked(result, "M");
                num -= 1000;
            } else if (num >= 900) {
                result = abi.encodePacked(result, "CM");
                num -= 900;
            } else if (num >= 500) {
                result = abi.encodePacked(result, "D");
                num -= 500;
            } else if (num >= 400) {
                result = abi.encodePacked(result, "CD");
                num -= 400;
            } else if (num >= 100) {
                result = abi.encodePacked(result, "C");
                num -= 100;
            } else if (num >= 90) {
                result = abi.encodePacked(result, "XC");
                num -= 90;
            } else if (num >= 50) {
                result = abi.encodePacked(result, "L");
                num -= 50;
            } else if (num >= 40) {
                result = abi.encodePacked(result, "XL");
                num -= 40;
            } else if (num >= 10) {
                result = abi.encodePacked(result, "X");
                num -= 10;
            } else if (num >= 9) {
                result = abi.encodePacked(result, "IX");
                num -= 9;
            } else if (num >= 5) {
                result = abi.encodePacked(result, "V");
                num -= 5;
            } else if (num >= 4) {
                result = abi.encodePacked(result, "IV");
                num -= 4;
            } else {
                result = abi.encodePacked(result, "I");
                num -= 1;
            }
        }
        
        return string(result);
    }
    
    // 测试函数
    function testAll() public pure returns (string[5] memory) {
        string[5] memory results;
        results[0] = intToRoman(3749); // "MMMDCCXLIX"
        results[1] = intToRoman(58);   // "LVIII"
        results[2] = intToRoman(1994); // "MCMXCIV"
        results[3] = intToRoman(3);    // "III"
        results[4] = intToRoman(4);    // "IV"
        return results;
    }
}