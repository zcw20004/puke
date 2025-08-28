// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title CardUtils
 * @dev 扑克牌相关工具库
 */
library CardUtils {
    // 花色枚举：方块、红桃、黑桃、梅花
    enum Suit { DIAMONDS, HEARTS, SPADES, CLUBS }
    
    // 卡牌结构体，包含花色和点数
    struct Card {
        Suit suit;     // 花色
        uint8 rank;    // 点数 (1=A, 11=J, 12=Q, 13=K)
    }
    
    // 牌型枚举：单张 < 对子 < 顺子 < 同花 < 同花顺 < 豹子
    // 注意：235顺子可以击败豹子，在比较函数中特殊处理
    enum HandType { HIGH_CARD, PAIR, STRAIGHT, FLUSH, STRAIGHT_FLUSH, THREE_KIND }

    /**
     * @dev 评估手牌类型和价值
     * @param cards 三张牌的数组
     * @return handType 牌型
     * @return handValue 牌值
     */
    function evaluateHand(Card[3] memory cards) internal pure returns (HandType, uint8) {
        // 排序（按点数）
        _sortCardsByRank(cards);
        
        // 提取点数和花色信息
        uint8[3] memory ranks = [cards[0].rank, cards[1].rank, cards[2].rank];
        bool isFlush = _isFlush(cards);
        bool isStraight = _isStraight(ranks);
        
        // 判断牌型
        if (ranks[0] == ranks[1] && ranks[1] == ranks[2]) {
            return (HandType.THREE_KIND, ranks[0]); // 豹子
        }
        
        if (isFlush && isStraight) {
            return (HandType.STRAIGHT_FLUSH, _getHighestRank(ranks)); // 同花顺
        }
        
        if (isFlush) {
            return (HandType.FLUSH, _getHighestRank(ranks)); // 同花
        }
        
        if (isStraight) {
            return (HandType.STRAIGHT, _getHighestRank(ranks)); // 顺子
        }
        
        if (ranks[0] == ranks[1] || ranks[1] == ranks[2] || ranks[0] == ranks[2]) {
            uint8 pairValue = ranks[0] == ranks[1] ? ranks[0] : 
                             ranks[1] == ranks[2] ? ranks[1] : ranks[0];
            return (HandType.PAIR, pairValue); // 对子
        }
        
        return (HandType.HIGH_CARD, _getHighestRank(ranks)); // 单张
    }

    /**
     * @dev 比较两手牌的大小
     * @param hand1Type 第一手牌类型
     * @param hand1Value 第一手牌值
     * @param hand2Type 第二手牌类型  
     * @param hand2Value 第二手牌值
     * @param hand1Cards 第一手牌（用于235特殊判断）
     * @param hand2Cards 第二手牌（用于235特殊判断）
     * @return true 如果第一手牌更大
     */
    function compareHands(
        HandType hand1Type, 
        uint8 hand1Value, 
        HandType hand2Type, 
        uint8 hand2Value,
        Card[3] memory hand1Cards,
        Card[3] memory hand2Cards
    ) internal pure returns (bool) {
        // 检查235特殊规则：235顺子可以击败豹子
        bool hand1Is235 = _is235Straight(hand1Cards);
        bool hand2Is235 = _is235Straight(hand2Cards);
        
        if (hand1Is235 && hand2Type == HandType.THREE_KIND) {
            return true; // 235击败豹子
        }
        if (hand2Is235 && hand1Type == HandType.THREE_KIND) {
            return false; // 豹子被235击败
        }
        
        // 正常比较规则
        if (hand1Type != hand2Type) {
            return hand1Type > hand2Type;
        }
        return hand1Value > hand2Value;
    }
    
    /**
     * @dev 检查是否为235顺子
     * @param cards 三张牌
     * @return 是否为235顺子
     */
    function _is235Straight(Card[3] memory cards) private pure returns (bool) {
        uint8[3] memory ranks;
        for (uint i = 0; i < 3; i++) {
            ranks[i] = cards[i].rank;
        }
        
        // 排序
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (ranks[j] > ranks[j + 1]) {
                    (ranks[j], ranks[j + 1]) = (ranks[j + 1], ranks[j]);
                }
            }
        }
        
        // 检查是否为 2, 3, 5 或 A, 2, 3
        return (ranks[0] == 2 && ranks[1] == 3 && ranks[2] == 5) ||
               (ranks[0] == 1 && ranks[1] == 2 && ranks[2] == 3);
    }

    /**
     * @dev 按点数对牌进行排序
     * @param cards 要排序的牌数组
     */
    function _sortCardsByRank(Card[3] memory cards) private pure {
        // 冒泡排序，按照游戏规则排序：A=14, K=13, Q=12, J=11, 10-2按数值
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                uint8 rank1 = _getRankValue(cards[j].rank);
                uint8 rank2 = _getRankValue(cards[j + 1].rank);
                if (rank1 > rank2) {
                    (cards[j], cards[j + 1]) = (cards[j + 1], cards[j]);
                }
            }
        }
    }
    
    /**
     * @dev 获取点数的实际数值（A=14, K=13, Q=12, J=11）
     * @param rank 原始点数
     * @return 转换后的数值
     */
    function _getRankValue(uint8 rank) private pure returns (uint8) {
        if (rank == 1) return 14; // A
        return rank;
    }
    
    /**
     * @dev 检查是否为同花
     * @param cards 三张牌
     * @return 是否为同花
     */
    function _isFlush(Card[3] memory cards) private pure returns (bool) {
        return cards[0].suit == cards[1].suit && cards[1].suit == cards[2].suit;
    }
    
    /**
     * @dev 检查是否为顺子
     * @param ranks 已排序的点数数组
     * @return 是否为顺子
     */
    function _isStraight(uint8[3] memory ranks) private pure returns (bool) {
        // 转换为游戏数值进行判断
        uint8[3] memory values;
        for (uint i = 0; i < 3; i++) {
            values[i] = _getRankValue(ranks[i]);
        }
        
        // 重新排序转换后的数值
        _sortValues(values);
        
        // 检查连续性
        if (values[0] + 1 == values[1] && values[1] + 1 == values[2]) {
            return true;
        }
        
        // 特殊情况：A23 (14, 2, 3)
        if (values[0] == 2 && values[1] == 3 && values[2] == 14) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev 排序数值数组
     * @param values 要排序的数值数组
     */
    function _sortValues(uint8[3] memory values) private pure {
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (values[j] > values[j + 1]) {
                    (values[j], values[j + 1]) = (values[j + 1], values[j]);
                }
            }
        }
    }
    
    /**
     * @dev 获取最高点数
     * @param ranks 点数数组
     * @return 最高点数的游戏数值
     */
    function _getHighestRank(uint8[3] memory ranks) private pure returns (uint8) {
        uint8 highest = 0;
        for (uint i = 0; i < 3; i++) {
            uint8 value = _getRankValue(ranks[i]);
            if (value > highest) {
                highest = value;
            }
        }
        return highest;
    }

    /**
     * @dev 验证牌是否有效
     * @param card 卡牌
     * @return true 如果牌有效
     */
    function isValidCard(Card memory card) internal pure returns (bool) {
        return card.rank >= 1 && card.rank <= 13 && 
               uint8(card.suit) <= 3; // 0-3 对应四种花色
    }
    
    /**
     * @dev 创建卡牌
     * @param suit 花色
     * @param rank 点数
     * @return 卡牌结构体
     */
    function createCard(Suit suit, uint8 rank) internal pure returns (Card memory) {
        require(rank >= 1 && rank <= 13, "Invalid rank");
        return Card(suit, rank);
    }
} 