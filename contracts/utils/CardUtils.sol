// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title CardUtils
 * @dev 扑克牌相关工具库
 */
library CardUtils {
    enum HandType { HIGH_CARD, PAIR, STRAIGHT, THREE_KIND }

    /**
     * @dev 评估手牌类型和价值
     * @param cards 三张牌的数组
     * @return handType 牌型
     * @return handValue 牌值
     */
    function evaluateHand(uint8[3] memory cards) internal pure returns (HandType, uint8) {
        // 排序
        _sortCards(cards);
        
        // 判断牌型
        if (cards[0] == cards[1] && cards[1] == cards[2]) {
            return (HandType.THREE_KIND, cards[0]); // 豹子
        }
        
        if (cards[0] + 1 == cards[1] && cards[1] + 1 == cards[2]) {
            return (HandType.STRAIGHT, cards[2]); // 顺子
        }
        
        if (cards[0] == cards[1] || cards[1] == cards[2] || cards[0] == cards[2]) {
            uint8 pairValue = cards[0] == cards[1] ? cards[0] : 
                             cards[1] == cards[2] ? cards[1] : cards[0];
            return (HandType.PAIR, pairValue); // 对子
        }
        
        return (HandType.HIGH_CARD, cards[2]); // 大牌
    }

    /**
     * @dev 比较两手牌的大小
     * @param hand1Type 第一手牌类型
     * @param hand1Value 第一手牌值
     * @param hand2Type 第二手牌类型  
     * @param hand2Value 第二手牌值
     * @return true 如果第一手牌更大
     */
    function compareHands(
        HandType hand1Type, 
        uint8 hand1Value, 
        HandType hand2Type, 
        uint8 hand2Value
    ) internal pure returns (bool) {
        if (hand1Type != hand2Type) {
            return hand1Type > hand2Type;
        }
        return hand1Value > hand2Value;
    }

    /**
     * @dev 对牌进行排序
     * @param cards 要排序的牌数组
     */
    function _sortCards(uint8[3] memory cards) private pure {
        // 冒泡排序
        if (cards[0] > cards[1]) {
            (cards[0], cards[1]) = (cards[1], cards[0]);
        }
        if (cards[1] > cards[2]) {
            (cards[1], cards[2]) = (cards[2], cards[1]);
        }
        if (cards[0] > cards[1]) {
            (cards[0], cards[1]) = (cards[1], cards[0]);
        }
    }

    /**
     * @dev 验证牌值是否有效
     * @param card 牌值
     * @return true 如果牌值有效（1-13）
     */
    function isValidCard(uint8 card) internal pure returns (bool) {
        return card >= 1 && card <= 13;
    }
} 