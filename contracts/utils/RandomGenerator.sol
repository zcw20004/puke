// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CardUtils.sol";

/**
 * @title RandomGenerator
 * @dev 随机数生成工具库
 */
library RandomGenerator {
    /**
     * @dev 生成随机卡牌
     * @param gameId 游戏ID
     * @param nonce 随机数种子
     * @param sender 调用者地址
     * @return 随机卡牌
     */
    function drawCard(uint256 gameId, uint256 nonce, address sender) internal view returns (CardUtils.Card memory) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            sender,
            gameId,
            nonce
        )));
        
        // 生成花色 (0-3)
        CardUtils.Suit suit = CardUtils.Suit(randomNum % 4);
        
        // 生成点数 (1-13)
        uint8 rank = uint8((randomNum / 4) % 13) + 1;
        
        return CardUtils.Card(suit, rank);
    }

    /**
     * @dev 生成指定范围内的随机数
     * @param seed 随机种子
     * @param max 最大值（不包含）
     * @return 0到max-1之间的随机数
     */
    function random(uint256 seed, uint256 max) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            seed
        )));
        return randomNum % max;
    }

    /**
     * @dev 生成随机种子
     * @param additionalEntropy 额外熵值
     * @return 随机种子
     */
    function generateSeed(uint256 additionalEntropy) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            additionalEntropy
        )));
    }
} 