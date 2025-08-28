// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./GameLogic.sol";

/**
 * @title GameRoom
 * @dev 游戏房间管理合约
 */
contract GameRoom is GameLogic {
    
    /**
     * @dev 创建游戏
     * @return gameId 游戏ID
     */
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

    /**
     * @dev 加入游戏
     * @param gameId 游戏ID
     */
    function joinGame(uint256 gameId) external payable gameExists(gameId) {
        require(games[gameId].state == GameState.WAITING, "Game not accepting players");
        require(games[gameId].players.length < MAX_PLAYERS, "Game full");
        require(msg.value >= INITIAL_CHIPS, "Insufficient chips");
        require(playerToGame[msg.sender] == 0, "Already in a game");
        
        _addPlayer(gameId, msg.sender, msg.value);
        
        emit PlayerJoined(msg.sender, gameId);
    }

    /**
     * @dev 开始游戏
     * @param gameId 游戏ID
     */
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

    /**
     * @dev 获取游戏信息
     * @param gameId 游戏ID
     * @return id 游戏ID
     * @return creator 创建者地址
     * @return playerCount 玩家数量
     * @return pot 奖池金额
     * @return state 游戏状态
     * @return winner 获胜者地址
     */
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

    /**
     * @dev 获取玩家手牌
     * @param gameId 游戏ID
     * @param playerAddr 玩家地址
     * @return 玩家的三张手牌
     */
    function getPlayerCards(uint256 gameId, address playerAddr) external view returns (CardUtils.Card[3] memory) {
        require(msg.sender == playerAddr, "Can only view own cards");
        Player storage player = _getPlayer(gameId, playerAddr);
        return player.cards;
    }

    /**
     * @dev 获取玩家信息
     * @param gameId 游戏ID
     * @param playerAddr 玩家地址
     * @return chips 玩家筹码数量
     * @return currentBet 当前下注金额
     * @return isActive 是否为活跃玩家
     */
    function getPlayerInfo(uint256 gameId, address playerAddr) external view returns (
        uint256 chips,
        uint256 currentBet,
        bool isActive
    ) {
        Player storage player = _getPlayer(gameId, playerAddr);
        return (player.chips, player.currentBet, player.isActive);
    }
} 