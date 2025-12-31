// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract vo{
    // 用 solidity 实现罗马数字转数整数
    function roman2Num(string memory str) public pure returns (uint256) {
        bytes memory roman = bytes(str);
        uint256 len = roman.length;
        int256 num = 0;
        for (uint256 i = 0; i < len; i++) {
            if (i < len - 1 && _getValue(roman[i]) < _getValue(roman[i + 1])) {
                num -= int256(_getValue(roman[i]));
            } else {
                num += int256(_getValue(roman[i]));
            }
        }
        return uint256(num);
    }
    /*
       results[0] = romanToInt("III");      // 3
        results[1] = romanToInt("IV");       // 4
        results[2] = romanToInt("IX");       // 9
        results[3] = romanToInt("LVIII");    // 58
        results[4] = romanToInt("MCMXCIV");  // 1994
    */
    function _getValue(bytes1 num) private pure returns (uint256) {
        if (num == "I") return 1;
        if (num == "V") return 5;
        if (num == "X") return 10;
        if (num == "L") return 50;
        if (num == "C") return 100;
        if (num == "D") return 500;
        if (num == "M") return 1000;
        return 0;
    }
}