// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../utils/CardUtils.sol";
import "../utils/RandomGenerator.sol";

/**
 * @title GameLogic
 * @dev 游戏核心逻辑合约
 */
contract GameLogic {
    using CardUtils for uint8[3];
    using RandomGenerator for uint256;

    // 游戏常量
    uint256 public constant INITIAL_CHIPS = 1000;
    uint256 public constant MIN_BET = 100;
    uint256 public constant MAX_PLAYERS = 4;

    // 游戏状态枚举
    enum GameState { WAITING, DEALING, BETTING, REVEALING, FINISHED }

    // 玩家结构体
    struct Player {
        address addr;
        uint256 chips;
        CardUtils.Card[3] cards;
        uint256 currentBet;
        bool isActive;
        bool hasCards;
    }

    // 游戏结构体
    struct Game {
        uint256 id;
        address creator;
        Player[] players;
        uint256 pot;
        GameState state;
        uint256 currentPlayer;
        address winner;
    }

    // 事件定义
    event GameCreated(address indexed creator, uint256 gameId);
    event PlayerJoined(address indexed player, uint256 gameId);
    event GameStarted(uint256 gameId);
    event BetPlaced(address indexed player, uint256 amount);
    event GameEnded(address indexed winner, uint256 winnings);

    // 状态变量
    uint256 public gameCounter;
    mapping(uint256 => Game) public games;
    mapping(address => uint256) public playerToGame;

    // 修饰符
    modifier onlyGameCreator(uint256 gameId) {
        require(games[gameId].creator == msg.sender, "Not game creator");
        _;
    }

    modifier gameExists(uint256 gameId) {
        require(games[gameId].creator != address(0), "Game does not exist");
        _;
    }

    modifier playerInGame(uint256 gameId) {
        require(playerToGame[msg.sender] == gameId, "Not in this game");
        _;
    }

    /**
     * @dev 发牌逻辑
     * @param gameId 游戏ID
     */
    function _dealCards(uint256 gameId) internal {
        Game storage game = games[gameId];
        
        for (uint i = 0; i < game.players.length; i++) {
            for (uint j = 0; j < 3; j++) {
                game.players[i].cards[j] = RandomGenerator.drawCard(gameId, i * 3 + j, msg.sender);
            }
            game.players[i].hasCards = true;
        }
    }

    /**
     * @dev 确定获胜者
     * @param gameId 游戏ID
     */
    function _determineWinner(uint256 gameId) internal {
        Game storage game = games[gameId];
        address winner = address(0);
        CardUtils.HandType bestType = CardUtils.HandType.HIGH_CARD;
        uint8 bestValue = 0;
        CardUtils.Card[3] memory bestCards;
        
        for (uint i = 0; i < game.players.length; i++) {
            if (!game.players[i].isActive) continue;
            
            (CardUtils.HandType handType, uint8 handValue) = CardUtils.evaluateHand(game.players[i].cards);
            
            // 如果是第一个玩家或者当前牌更大
            if (winner == address(0)) {
                winner = game.players[i].addr;
                bestType = handType;
                bestValue = handValue;
                bestCards = game.players[i].cards;
            } else {
                bool isBetter = CardUtils.compareHands(
                    handType, handValue, bestType, bestValue,
                    game.players[i].cards, bestCards
                );
                if (isBetter) {
                    winner = game.players[i].addr;
                    bestType = handType;
                    bestValue = handValue;
                    bestCards = game.players[i].cards;
                }
            }
        }
        
        game.winner = winner;
    }

    /**
     * @dev 分配奖金
     * @param gameId 游戏ID
     */
    function _distributeWinnings(uint256 gameId) internal {
        Game storage game = games[gameId];
        require(game.winner != address(0), "No winner determined");
        
        // 找到获胜者并分配奖金
        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i].addr == game.winner) {
                game.players[i].chips += game.pot;
                break;
            }
        }
        
        emit GameEnded(game.winner, game.pot);
    }

    /**
     * @dev 检查游戏是否结束
     * @param gameId 游戏ID
     */
    function _checkGameEnd(uint256 gameId) internal {
        Game storage game = games[gameId];
        uint activeCount = 0;
        address lastActive = address(0);
        
        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i].isActive) {
                activeCount++;
                lastActive = game.players[i].addr;
            }
        }
        
        if (activeCount == 1) {
            game.winner = lastActive;
            _distributeWinnings(gameId);
            game.state = GameState.FINISHED;
        }
    }

    /**
     * @dev 获取游戏中的玩家
     * @param gameId 游戏ID
     * @param playerAddr 玩家地址
     * @return 玩家信息的存储引用
     */
    function _getPlayer(uint256 gameId, address playerAddr) internal view returns (Player storage) {
        Game storage game = games[gameId];
        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i].addr == playerAddr) {
                return game.players[i];
            }
        }
        revert("Player not found");
    }

    /**
     * @dev 添加玩家到游戏
     * @param gameId 游戏ID
     * @param playerAddr 玩家地址
     * @param chips 筹码数量
     */
    function _addPlayer(uint256 gameId, address playerAddr, uint256 chips) internal {
        // 创建空卡牌数组
        CardUtils.Card[3] memory emptyCards;
        for (uint i = 0; i < 3; i++) {
            emptyCards[i] = CardUtils.Card(CardUtils.Suit.DIAMONDS, 1);
        }
        
        games[gameId].players.push(Player({
            addr: playerAddr,
            chips: chips,
            cards: emptyCards,
            currentBet: 0,
            isActive: true,
            hasCards: false
        }));
        
        playerToGame[playerAddr] = gameId;
    }
} 