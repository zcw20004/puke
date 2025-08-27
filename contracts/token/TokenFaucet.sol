// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PokerToken.sol";
import "../access/Ownable.sol";

/**
 * @title TokenFaucet  
 * @dev 代币水龙头，用于测试环境分发代币
 */
contract TokenFaucet is Ownable {
    PokerToken public token;
    uint256 public faucetAmount = 1000 * 10**18; // 每次发放1000个代币
    uint256 public cooldownTime = 1 days; // 冷却时间24小时
    
    mapping(address => uint256) public lastClaimTime;
    
    event TokensClaimed(address indexed user, uint256 amount);
    event FaucetAmountUpdated(uint256 newAmount);
    event CooldownTimeUpdated(uint256 newTime);

    constructor(address _tokenAddress) {
        token = PokerToken(_tokenAddress);
    }

    /**
     * @dev 申请代币
     */
    function claimTokens() external {
        require(canClaim(msg.sender), "Still in cooldown period");
        
        lastClaimTime[msg.sender] = block.timestamp;
        token.mint(msg.sender, faucetAmount);
        
        emit TokensClaimed(msg.sender, faucetAmount);
    }

    /**
     * @dev 检查用户是否可以申请代币
     * @param user 用户地址
     * @return 是否可以申请
     */
    function canClaim(address user) public view returns (bool) {
        return block.timestamp >= lastClaimTime[user] + cooldownTime;
    }

    /**
     * @dev 获取下次可申请时间
     * @param user 用户地址
     * @return 时间戳
     */
    function nextClaimTime(address user) external view returns (uint256) {
        if (canClaim(user)) {
            return block.timestamp;
        }
        return lastClaimTime[user] + cooldownTime;
    }

    /**
     * @dev 设置每次发放数量
     * @param _amount 新的发放数量
     */
    function setFaucetAmount(uint256 _amount) external onlyOwner {
        faucetAmount = _amount;
        emit FaucetAmountUpdated(_amount);
    }

    /**
     * @dev 设置冷却时间
     * @param _time 新的冷却时间（秒）
     */
    function setCooldownTime(uint256 _time) external onlyOwner {
        cooldownTime = _time;
        emit CooldownTimeUpdated(_time);
    }

    /**
     * @dev 紧急提取代币
     * @param amount 提取数量
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
} 