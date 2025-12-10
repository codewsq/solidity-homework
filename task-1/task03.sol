// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
3.用 solidity 实现整数转罗马数字
*/
contract RomanToInteger {
    // 主函数：罗马数字转整数
    function romanToInt(string memory s) public pure returns (uint256) {
        bytes memory roman = bytes(s);  // 将字符串转换为字节数组
        uint256 length = roman.length;
        uint256 result = 0;
        
        for (uint256 i = 0; i < length; i++) {
            // 获取当前字符的值
            uint256 current = _getValue(roman[i]);
            
            // 检查是否需要特殊处理（当前字符小于下一个字符）
            if (i < length - 1 && current < _getValue(roman[i + 1])) {
                result -= current;  // 特殊情况：减去当前值
            } else {
                result += current;  // 正常情况：加上当前值
            }
        }
        
        return result;
    }
    
    // 辅助函数：获取单个罗马数字字符的值
    function _getValue(bytes1 romanChar) private pure returns (uint256) {
        // 使用 if-else 语句直接比较字符
        if (romanChar == "I") return 1;
        if (romanChar == "V") return 5;
        if (romanChar == "X") return 10;
        if (romanChar == "L") return 50;
        if (romanChar == "C") return 100;
        if (romanChar == "D") return 500;
        if (romanChar == "M") return 1000;
        
        revert("Invalid Roman numeral character");
    }
    
    // 测试函数
    function test() public pure returns (uint256[5] memory results) {
        results[0] = romanToInt("III");      // 3
        results[1] = romanToInt("IV");       // 4
        results[2] = romanToInt("IX");       // 9
        results[3] = romanToInt("LVIII");    // 58
        results[4] = romanToInt("MCMXCIV");  // 1994
    }
    
    // 详细解释示例
    function explainMCMXCIV() public pure returns (string memory) {
        return "M=1000, CM=900, XC=90, IV=4 => 1000+900+90+4=1994";
    }
}