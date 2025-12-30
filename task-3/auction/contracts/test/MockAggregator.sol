// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract MockAggregator {
    int256 public price;
    uint8 public decimals = 8;

    constructor(int256 _price) {
        price = _price;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, block.timestamp, block.timestamp, 0);
    }

    function setPrice(int256 _price) external {
        price = _price;
    }
}
