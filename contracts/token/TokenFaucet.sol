// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PokerToken.sol";
import "../access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenFaucet  
 * @dev 代币水龙头，用于测试环境分发代币
 */
contract TokenFaucet is Ownable {
    using SafeERC20 for IERC20;
    
    PokerToken public token;
    address public tokenOwner; // PokerToken的所有者地址
    uint256 public faucetAmount = 1000 * 10**18; // 每次发放1000个代币
    uint256 public cooldownTime = 1 days; // 冷却时间24小时
    
    mapping(address => uint256) public lastClaimTime;
    
    event TokensClaimed(address indexed user, uint256 amount);
    event FaucetAmountUpdated(uint256 newAmount);
    event CooldownTimeUpdated(uint256 newTime);

    constructor(address _tokenAddress, address _tokenOwner) {
        token = PokerToken(_tokenAddress);
        tokenOwner = _tokenOwner;
    }

    /**
     * @dev 申请代币
     */
    function claimTokens() external {
        require(canClaim(msg.sender), "Still in cooldown period");
        require(IERC20(token).balanceOf(address(this)) >= faucetAmount, "Insufficient faucet balance");
        
        lastClaimTime[msg.sender] = block.timestamp;
        IERC20(token).safeTransfer(msg.sender, faucetAmount);
        
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
     * @dev 向水龙头添加代币
     * @param amount 添加数量
     */
    function addTokens(uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev 获取水龙头当前代币余额
     * @return 当前余额
     */
    function getFaucetBalance() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev 为测试环境mint代币到水龙头（只有token owner可以调用）
     * @param amount mint数量
     */
    function mintToFaucet(uint256 amount) external {
        require(msg.sender == token.owner(), "Only token owner can mint");
        token.mint(address(this), amount);
    }

    /**
     * @dev 紧急提取代币
     * @param amount 提取数量
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).safeTransfer(owner(), amount);
    }
} 