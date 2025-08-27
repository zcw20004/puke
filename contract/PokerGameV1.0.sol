// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// 导入模块化的游戏合约
import "./game/PokerGame.sol" as GameContract;

/**
 * @title PokerGame
 * @dev 主合约，直接继承模块化的PokerGame
 * 这个合约保持原有的接口兼容性，确保测试能正常运行
 */
contract PokerGame is GameContract.PokerGame {
    // 直接继承，无需额外代码
    // 所有功能都通过继承的模块获得
}