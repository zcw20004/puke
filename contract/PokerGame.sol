// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PokerGame {

    event GameCreated(address indexed creator, uint256 gameId);
    event PlayerJoined(address indexed player, uint256 gameId);
    event GameStarted(uint256 gameId);
    event BetPlaced(address indexed player, uint256 amount);
    event GameEnded(address indexed winner, uint256 winnings);

    struct Player {
        address addr; // 玩家地址
        uint256 chips; // 筹码余额
        uint8[3] cards; // 手牌
        uint256 currentBet; // 当前下注
        bool isActive; // 是否还在游戏中
        bool hasCards; // 是否还有手牌
    }
    
    struct Game {
        uint256 id; // 游戏ID
        address creator; // 创建者
        Player[] players; // 玩家列表
        uint256 pot; // 当前池子
        GameState state; // 游戏状态
        uint256 currentPlayer; // 当前玩家
        address winner; // 赢家
    }

    uint8 private constant MAX_PLAYERS = 4;

    mapping(uint256 => Game) public games;
    mapping(address => uint256) public joinedGames;
    uint256 public gameCount = 0;
    uint256 public constant minBet = 100; // 最小下注
    uint256 public constant currentBet = 1000; 

    // 游戏状态
    enum GameState {
        WAITING,    // 等待玩家
        DEALING,    // 发牌
        BETTING,    // 下注
        REVEALING,  // 比牌
        FINISHED    // 结束
    }

    // 牌型枚举
    enum HandType {
        HIGH_CARD,  // 大牌
        PAIR,       // 对子  
        STRAIGHT,   // 顺子
        THREE_KIND  // 豹子
    }

    modifier checkGameExists(uint256 gameId) {
        require(games[gameId].creator != address(0), "Game not found");
        _;
    }

    modifier checkPlayerNotJoined(uint256 gameId) {
        require(joinedGames[msg.sender] != gameId, "Player already joined");
        _;
    }
    
    // 创建游戏
    function createGame() external payable {
        gameCount++;
        games[gameCount] = Game({
            id: gameCount,
            creator: msg.sender,
            players: new Player[](0),
            pot: 0,
            state: GameState.WAITING,
            currentPlayer: 0,
            winner: address(0)
        });

            // 创建者自动加入游戏 - 添加这部分
        games[gameCount].players.push(Player({
            addr: msg.sender,
            chips: msg.value,
            cards: [0, 0, 0],
            currentBet: 0,
            isActive: true,
            hasCards: false
        }));
        
        joinedGames[msg.sender] = gameCount;
    }

    function joinGame(uint256 gameId) external payable checkGameExists(gameId) checkPlayerNotJoined(gameId) {
        // 创建新玩家， 分配初始筹码    
        games[gameId].players.push(Player({
            addr: msg.sender,
            chips: msg.value,
            cards: [0, 0, 0],
            currentBet: currentBet, 
            isActive: true,
            hasCards: true
        }));

        // emit PlayerJoined(msg.sender, msg.value);
    
    }

    function startGame(uint256 gameId) external checkGameExists(gameId) {
        Game storage game = games[gameId];
        require(game.creator == msg.sender, "Only creator can start game");
        require(game.players.length >= 2, "At least 2 players are required");

        game.state = GameState.DEALING;
        dealCards(gameId);
        game.state = GameState.BETTING;
    }

    function placeBet(uint256 gameId, uint256 amount) external checkGameExists(gameId) {
        Game storage game = games[gameId];
        require(game.state == GameState.BETTING, "Game is not in betting phase");
        require(joinedGames[msg.sender] == gameId, "Player not in this game"); // 添加身份验证
        
        // 找到调用者对应的玩家
        Player storage player;
        bool found = false;
        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i].addr == msg.sender) {
                player = game.players[i];
                found = true;
                break;
            }
        }
        require(found, "Player not found");
        require(player.chips >= amount, "Insufficient chips"); // 检查余额
        
        player.chips -= amount; // 扣除筹码
        player.currentBet += amount;
        game.pot += amount;
    }

    function fold(uint256 gameId) external checkGameExists(gameId) {
        Game storage game = games[gameId];
        require(game.state == GameState.BETTING, "Game is not in betting phase");
        require(game.currentPlayer < game.players.length, "No current player");

        game.players[game.currentPlayer].isActive = false;

        game.currentPlayer++;
        if (game.currentPlayer >= game.players.length) {
            game.currentPlayer = 0;
        }
    }

    function showdown(uint256 gameId) external checkGameExists(gameId) {
        Game storage game = games[gameId];
        require(game.state == GameState.REVEALING, "Game is not in revealing phase");
        require(game.currentPlayer < game.players.length, "No current player");

        // game.state = GameState.FINISHED;
        uint8 winnerIndex = 0;
        // 比较手牌
        for (uint8 i = 1; i < game.players.length; i++) {
            game.winner = compareHands(game.players[i - 1].cards, game.players[i].cards);
            if (game.winner == address(1)) {
                winnerIndex = i - 1;
            } else if (game.winner == address(2)) {
                winnerIndex = i;
            }
        }
        // 计算平局
        if (game.winner == address(0)) {
            for (uint256 i = 0; i < game.players.length; i++) {
                game.players[i].chips += game.pot / game.players.length;
            }
        } else {
            // 计算赢家，分配奖金
            game.players[winnerIndex].chips += game.pot;
            // 计算输家
            for (uint8 i = 0; i < game.players.length; i++) {
                if (i != winnerIndex) {
                    game.players[i].chips -= game.pot / (game.players.length - 1);
                    // 判断玩家筹码，如果筹码不够则游戏结束
                    if (game.players[i].chips < minBet) {
                        game.players[i].isActive = false;
                        game.state = GameState.FINISHED;
                        return;
                    }
                }
            }
        }
        // 更新游戏状态
        game.state = GameState.WAITING;
    }

    function dealCards(uint256 gameId) internal {
        Game storage game = games[gameId];
        require(game.state == GameState.DEALING, "Game is not in dealing phase");
        // 发牌
        for (uint256 i = 0; i < game.players.length; i++) {
            // 这里要从小到达排序一下
            uint8 card1 = getRandomCard(i);
            uint8 card2 = getRandomCard(i);
            uint8 card3 = getRandomCard(i);
            unchecked {
                (card1, card2) = card1 > card2 ? (card2, card1) : (card1, card2);
                (card2, card3) = card2 > card3 ? (card3, card2) : (card2, card3);
                (card1, card2) = card1 > card2 ? (card2, card1) : (card1, card2);
            }
            game.players[i].cards[0] = card1;
            game.players[i].cards[1] = card2;
            game.players[i].cards[2] = card3;
        }
        // 更新游戏状态
        game.state = GameState.BETTING;
    }

    // 防止矿工操控随机数
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            block.coinbase,
            seed,
            msg.sender
        )));
    }
    function getRandomCard(uint256 nonce) internal view returns (uint8) {
        return uint8(random(nonce) % 13) + 1; // 1-13 (A,2,3...K)
    }

    function evaluateHand(uint8[3] memory cards) internal pure returns (HandType, uint8) {
        HandType handType;
        uint8 highCard;
        // 计算手牌类型
        if (cards[0] == cards[1] && cards[1] == cards[2]) {
            handType = HandType.THREE_KIND;
            highCard = cards[0];
        } else if (cards[0] == cards[1] || cards[1] == cards[2] || cards[0] == cards[2]) {
            handType = HandType.PAIR;
            highCard = cards[0] > cards[1] ? cards[0] : cards[1];
        } else if (cards[0] + 1 == cards[1] && cards[1] + 1 == cards[2]) {
            // 这个是假设 从小到大排序
            handType = HandType.STRAIGHT;
            highCard = cards[2];
        } else {
            handType = HandType.HIGH_CARD;
            highCard = cards[2];
        }

        return (handType, highCard);
    }

    function compareHands(uint8[3] memory cards1, uint8[3] memory cards2) internal pure returns (address) {
        (HandType handType1, uint8 highCard1) = evaluateHand(cards1);
        (HandType handType2, uint8 highCard2) = evaluateHand(cards2);

        if (handType1 > handType2) {
            return address(1);
        } else if (handType1 < handType2) {
            return address(2);
        } else {
            if (highCard1 > highCard2) {
                return address(1);
            } else if (highCard1 < highCard2) {
                return address(2);
            }
            return address(0);
        }
    }

    // function distributeWinnings(uint256 gameId) internal {
    //     // 分配奖金
    // }
 
}


