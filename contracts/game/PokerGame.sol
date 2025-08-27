// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./GameRoom.sol";

/**
 * @title PokerGame
 * @dev 主要的炸金花游戏合约
 */
contract PokerGame is GameRoom {
    
    /**
     * @dev 下注
     * @param gameId 游戏ID
     * @param amount 下注金额
     */
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

    /**
     * @dev 弃牌
     * @param gameId 游戏ID
     */
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

    /**
     * @dev 摊牌
     * @param gameId 游戏ID
     */
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
} 