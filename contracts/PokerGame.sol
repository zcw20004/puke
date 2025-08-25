// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PokerGame {
    // 事件定义
    event GameCreated(address indexed creator, uint256 gameId);
    event PlayerJoined(address indexed player, uint256 gameId);
    event GameStarted(uint256 gameId);
    event BetPlaced(address indexed player, uint256 amount);
    event GameEnded(address indexed winner, uint256 winnings);
    
    // 状态变量
    uint256 public constant INITIAL_CHIPS = 1000;
    uint256 public constant MIN_BET = 100;
    uint256 public constant MAX_PLAYERS = 4;
    
    uint256 public gameCounter;
    
    struct Player {
        address addr;
        uint256 chips;
        uint8[3] cards;
        uint256 currentBet;
        bool isActive;
        bool hasCards;
    }
    
    struct Game {
        uint256 id;
        address creator;
        Player[] players;
        uint256 pot;
        GameState state;
        uint256 currentPlayer;
        address winner;
    }
    
    enum GameState { WAITING, DEALING, BETTING, REVEALING, FINISHED }
    enum HandType { HIGH_CARD, PAIR, STRAIGHT, THREE_KIND }
    
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
    
    // 主要功能函数
    function createGame() external payable returns (uint256) {
        require(msg.value >= INITIAL_CHIPS, "Insufficient chips");
        
        gameCounter++;
        uint256 gameId = gameCounter;
        
        games[gameId].id = gameId;
        games[gameId].creator = msg.sender;
        games[gameId].state = GameState.WAITING;
        
        // 创建者自动加入游戏
        _addPlayer(gameId, msg.sender, msg.value);
        
        emit GameCreated(msg.sender, gameId);
        return gameId;
    }
    
    function joinGame(uint256 gameId) external payable gameExists(gameId) {
        require(games[gameId].state == GameState.WAITING, "Game not accepting players");
        require(games[gameId].players.length < MAX_PLAYERS, "Game full");
        require(msg.value >= INITIAL_CHIPS, "Insufficient chips");
        require(playerToGame[msg.sender] == 0, "Already in a game");
        
        _addPlayer(gameId, msg.sender, msg.value);
        
        emit PlayerJoined(msg.sender, gameId);
    }
    
    function startGame(uint256 gameId) external 
        onlyGameCreator(gameId) 
        gameExists(gameId) 
    {
        require(games[gameId].state == GameState.WAITING, "Game already started");
        require(games[gameId].players.length >= 2, "Need at least 2 players");
        
        games[gameId].state = GameState.DEALING;
        _dealCards(gameId);
        games[gameId].state = GameState.BETTING;
        
        emit GameStarted(gameId);
    }
    
    function placeBet(uint256 gameId, uint256 amount) external 
        gameExists(gameId) 
        playerInGame(gameId) 
    {
        require(games[gameId].state == GameState.BETTING, "Not betting phase");
        require(amount >= MIN_BET, "Bet too small");
        
        Player storage player = _getPlayer(gameId, msg.sender);
        require(player.isActive, "Player not active");
        require(player.chips >= amount, "Insufficient chips");
        
        player.chips -= amount;
        player.currentBet += amount;
        games[gameId].pot += amount;
        
        emit BetPlaced(msg.sender, amount);
    }
    
    function fold(uint256 gameId) external 
        gameExists(gameId) 
        playerInGame(gameId) 
    {
        require(games[gameId].state == GameState.BETTING, "Not betting phase");
        
        Player storage player = _getPlayer(gameId, msg.sender);
        player.isActive = false;
        
        // 检查是否只剩一个玩家
        _checkGameEnd(gameId);
    }
    
    function showdown(uint256 gameId) external 
        gameExists(gameId) 
        playerInGame(gameId) 
    {
        require(games[gameId].state == GameState.BETTING, "Not betting phase");
        
        // 简化版：任何玩家都可以触发摊牌
        games[gameId].state = GameState.REVEALING;
        _determineWinner(gameId);
        _distributeWinnings(gameId);
        games[gameId].state = GameState.FINISHED;
    }
    
    // 内部辅助函数
    function _addPlayer(uint256 gameId, address playerAddr, uint256 chips) internal {
        games[gameId].players.push(Player({
            addr: playerAddr,
            chips: chips,
            cards: [0, 0, 0],
            currentBet: 0,
            isActive: true,
            hasCards: false
        }));
        
        playerToGame[playerAddr] = gameId;
    }
    
    function _dealCards(uint256 gameId) internal {
        Game storage game = games[gameId];
        
        for (uint i = 0; i < game.players.length; i++) {
            for (uint j = 0; j < 3; j++) {
                game.players[i].cards[j] = _drawCard(gameId, i * 3 + j);
            }
            game.players[i].hasCards = true;
        }
    }
    
    function _drawCard(uint256 gameId, uint256 nonce) internal view returns (uint8) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            gameId,
            nonce
        )));
        return uint8((randomNum % 13) + 1); // 1-13
    }
    
    function _evaluateHand(uint8[3] memory cards) internal pure returns (HandType, uint8) {
        // 排序
        if (cards[0] > cards[1]) {
            (cards[0], cards[1]) = (cards[1], cards[0]);
        }
        if (cards[1] > cards[2]) {
            (cards[1], cards[2]) = (cards[2], cards[1]);
        }
        if (cards[0] > cards[1]) {
            (cards[0], cards[1]) = (cards[1], cards[0]);
        }
        
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
    
    function _determineWinner(uint256 gameId) internal {
        Game storage game = games[gameId];
        address winner = address(0);
        HandType bestType = HandType.HIGH_CARD;
        uint8 bestValue = 0;
        
        for (uint i = 0; i < game.players.length; i++) {
            if (!game.players[i].isActive) continue;
            
            (HandType handType, uint8 handValue) = _evaluateHand(game.players[i].cards);
            
            if (handType > bestType || (handType == bestType && handValue > bestValue)) {
                winner = game.players[i].addr;
                bestType = handType;
                bestValue = handValue;
            }
        }
        
        game.winner = winner;
    }
    
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
    
    function _getPlayer(uint256 gameId, address playerAddr) internal view returns (Player storage) {
        Game storage game = games[gameId];
        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i].addr == playerAddr) {
                return game.players[i];
            }
        }
        revert("Player not found");
    }
    
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
    
    // 查询函数
    function getGame(uint256 gameId) external view returns (
        uint256 id,
        address creator,
        uint256 playerCount,
        uint256 pot,
        GameState state,
        address winner
    ) {
        Game storage game = games[gameId];
        return (
            game.id,
            game.creator,
            game.players.length,
            game.pot,
            game.state,
            game.winner
        );
    }
    
    function getPlayerCards(uint256 gameId, address playerAddr) external view returns (uint8[3] memory) {
        require(msg.sender == playerAddr, "Can only view own cards");
        Player storage player = _getPlayer(gameId, playerAddr);
        return player.cards;
    }
    
    function getPlayerInfo(uint256 gameId, address playerAddr) external view returns (
        uint256 chips,
        uint256 currentBet,
        bool isActive
    ) {
        Player storage player = _getPlayer(gameId, playerAddr);
        return (player.chips, player.currentBet, player.isActive);
    }
}