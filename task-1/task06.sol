// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinarySearch {
    // 二分查找函数
    function binarySearch(uint256[] memory arr, uint256 target) public pure returns (int256) {
        uint256 left = 0;
        uint256 right = arr.length;
        
        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            if (arr[mid] == target) {
                return int256(mid); // 找到目标，返回索引
            } else if (arr[mid] < target) {
                left = mid + 1; // 目标在右半部分
            } else {
                right = mid; // 目标在左半部分
            }
        }
        
        return -1; // 未找到目标
    }
    
    // 测试函数
    function testBinarySearch() public pure returns (int256[4] memory) {
        uint256[] memory arr = new uint256[](10);
        arr[0] = 1;
        arr[1] = 3;
        arr[2] = 5;
        arr[3] = 7;
        arr[4] = 9;
        arr[5] = 11;
        arr[6] = 13;
        arr[7] = 15;
        arr[8] = 17;
        arr[9] = 19;
        
        int256[4] memory results;
        results[0] = binarySearch(arr, 7);   // 应该返回 3
        results[1] = binarySearch(arr, 1);   // 应该返回 0
        results[2] = binarySearch(arr, 19);  // 应该返回 9
        results[3] = binarySearch(arr, 8);   // 应该返回 -1
        
        return results;
    }
}