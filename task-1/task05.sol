// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/*
5.合并两个有序数组 (Merge Sorted Array)
题目描述：将两个有序数组合并为一个有序数组。
*/
contract mergeArraySort{
    event Number(uint[] numbers);
    event Result(uint[] numbers);
    uint[] public numbers;
    function mergerArray(uint[] memory a,uint[] calldata b) public returns (uint[] memory){
        for (uint i = 0; i<a.length; i++) {
            numbers.push(a[i]);
        }
        for (uint i = 0; i<b.length; i++) {
            numbers.push(b[i]);
        }
        emit Number(numbers);
        uint[] memory result = arraySort(numbers);
        emit Result(result);
        return result;
    }

    // 冒泡排序 ["1","3","5","7","9"] ["2","4","6","8","10","12"]
    function arraySort(uint[] memory a) public pure returns(uint[] memory){
        uint len = a.length;
        // 外层循环控制排序轮数
        for(uint i = 0;i<len - uint(1); i++){
            // 内层循环进行相邻元素比较和交换
            for(uint j = 0;j < len-1-i;j++){
                if (a[j] > a[j+1]){
                    uint temp = a[j];
                    a[j] = a[j+1];
                    a[j+1] = temp;
                }
            }
        }
        return (a);
    }
}