# PokerGame 合约测试指南

## 项目概述

这是一个基于 Hardhat 3.0.0 框架的智能合约炸金花游戏项目。本指南将详细介绍如何在本地网络上运行和测试 `PokerGame` 合约。

## 环境要求

- Node.js (推荐 16+ 版本)
- Hardhat 3.0.0
- TypeScript

## 项目结构

```
puke-poker/
├── contracts/
│   ├── access/           # 访问控制
│   │   ├── Ownable.sol
│   │   └── Pausable.sol
│   ├── token/            # 代币相关
│   │   ├── PokerToken.sol
│   │   └── TokenFaucet.sol
│   ├── utils/            # 工具库
│   │   ├── CardUtils.sol
│   │   ├── RandomGenerator.sol
│   │   └── SafeMath.sol
│   ├── game/             # 游戏逻辑
│   │   ├── GameLogic.sol
│   │   ├── GameRoom.sol
│   │   └── PokerGame.sol
│   └── PokerGame.sol     # 主合约（继承模块化合约）
├── test/
│   ├── PokerGame.ts           # PokerGame 合约测试文件
│   └── Counter.ts             # 示例测试文件
├── hardhat.config.ts          # Hardhat 配置文件
├── package.json               # 项目依赖配置
└── tsconfig.json              # TypeScript 配置
```

## 可用的测试命令

### 1. 编译合约
```bash
npm run compile
```
编译所有 Solidity 合约，确保没有语法错误。

### 2. 运行所有测试
```bash
npm test
```
运行项目中的所有测试文件。

### 3. 只运行 PokerGame 测试
```bash
npm run test:poker
```
专门运行 PokerGame 合约的测试用例。

### 4. 启动本地网络节点
```bash
npm run node
```
启动 Hardhat 本地区块链网络，可以在另一个终端中运行测试。

## 测试内容详解

我们为 `PokerGame` 合约创建了全面的测试用例，涵盖以下功能：

### 基本游戏功能测试
1. **游戏创建** - 验证能否成功创建游戏
2. **筹码验证** - 测试筹码不足时的错误处理
3. **玩家加入** - 测试玩家加入游戏机制
4. **游戏开始** - 验证游戏开始逻辑
5. **下注功能** - 测试下注机制
6. **弃牌功能** - 测试弃牌和游戏结束逻辑
7. **手牌查看** - 验证玩家只能查看自己的手牌
8. **摊牌功能** - 测试摊牌和获胜者确定

### 错误条件测试
1. **权限控制** - 测试非创建者不能开始游戏
2. **下注限制** - 验证最小下注金额限制
3. **数据验证** - 测试查询不存在游戏的错误处理

## 合约常量说明

- `INITIAL_CHIPS = 1000` - 初始筹码（以 wei 为单位）
- `MIN_BET = 100` - 最小下注金额（以 wei 为单位）
- `MAX_PLAYERS = 4` - 最大玩家数量

## 游戏状态枚举

```solidity
enum GameState { WAITING, DEALING, BETTING, REVEALING, FINISHED }
```

- `WAITING` - 等待玩家加入
- `DEALING` - 发牌中
- `BETTING` - 下注阶段
- `REVEALING` - 摊牌阶段
- `FINISHED` - 游戏结束

## 手牌类型
1. **手牌类型枚举**:
```solidity
enum HandType { HIGH_CARD, PAIR, STRAIGHT, THREE_KIND }
```

- `HIGH_CARD` - 高牌
- `PAIR` - 对子
- `STRAIGHT` - 顺子
- `THREE_KIND` - 豹子（三条）

2. **牌型大小**:
   - 豹子（三张相同）> 同花顺 > 同花 > 顺子 > 对子 > 单张
   - 特殊：235、123（最小顺子）可以击败豹子
3. **比牌规则**: 点数大小 A > K > Q > J > 10 > 9 > 8 > 7 > 6 > 5 > 4 > 3 > 2
4. **牌型比较**: 优先比较牌型，再比较点数大小
5. **牌型相同**: 比较点数大小，点数大的获胜
6. **牌型不同**: 牌型大的获胜
7. **平局**: 重新洗牌，重新比牌

## 运行测试的步骤

1. **安装依赖**（如果还没有安装）
   ```bash
   npm install
   ```

2. **编译合约**
   ```bash
   npm run compile
   ```

3. **运行测试**
   ```bash
   npm run test:poker
   ```

## 常见问题

### Q: 编译时出现 Solidity 版本错误
A: 确保使用 Solidity 0.8.28 版本，这在 `hardhat.config.ts` 中已配置。

### Q: 测试运行缓慢
A: 这是正常的，智能合约测试需要模拟区块链环境，会比较耗时。

### Q: 想要调试特定测试用例
A: 可以在测试文件中使用 `it.only()` 来只运行特定的测试用例。

## 下一步

- 可以尝试修改合约代码，观察测试结果的变化
- 添加更多测试用例来覆盖边界情况
- 考虑添加集成测试来测试完整的游戏流程
- 部署到测试网络进行更真实的测试

## 技术栈

- **Hardhat 3.0.0** - 以太坊开发环境
- **Viem** - 现代的以太坊客户端库
- **TypeScript** - 类型安全的 JavaScript
- **Node.js Test Runner** - 内置测试框架
