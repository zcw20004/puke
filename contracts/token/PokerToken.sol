// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../access/Ownable.sol";

/**
 * @title PokerToken
 * @dev 炸金花游戏代币合约，使用 SafeERC20 实现
 */
contract PokerToken is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    event Mint(address indexed to, uint256 value);

    constructor(uint256 initialSupply) ERC20("Poker Token", "PKR") {
        _mint(msg.sender, initialSupply * 10**decimals());
        emit Mint(msg.sender, initialSupply * 10**decimals());
    }

    /**
     * @dev 铸造新代币，只有合约所有者可以调用
     * @param to 接收代币的地址
     * @param amount 铸造的代币数量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /**
     * @dev 安全转账代币
     * @param token 代币合约地址
     * @param to 接收代币的地址
     * @param amount 代币数量
     */
    function safeTransfer(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    /**
     * @dev 安全授权代币
     * @param token 代币合约地址
     * @param spender 被授权的地址
     * @param amount 授权数量
     */
    function safeApprove(IERC20 token, address spender, uint256 amount) external onlyOwner {
        token.safeApprove(spender, amount);
    }

    /**
     * @dev 安全从指定地址转账代币
     * @param token 代币合约地址
     * @param from 转出代币的地址
     * @param to 接收代币的地址
     * @param amount 代币数量
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) external onlyOwner {
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev 增加授权额度
     * @param token 代币合约地址
     * @param spender 被授权的地址
     * @param addedValue 增加的授权数量
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 addedValue) external onlyOwner {
        token.safeIncreaseAllowance(spender, addedValue);
    }

    /**
     * @dev 减少授权额度
     * @param token 代币合约地址
     * @param spender 被授权的地址
     * @param subtractedValue 减少的授权数量
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 subtractedValue) external onlyOwner {
        token.safeDecreaseAllowance(spender, subtractedValue);
    }
}