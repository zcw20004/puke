import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// 定义初始代币供应量
const INITIAL_TOKEN_SUPPLY = 1000000n; // 1,000,000 tokens

export default buildModule("PokerGameModule", (m) => {
  // 部署工具库
  // 注意：库不需要显式部署，它们会在使用它们的合约部署时自动链接

  // 部署 PokerToken
  const pokerToken = m.contract("PokerToken", [INITIAL_TOKEN_SUPPLY]);

  // 部署 TokenFaucet
  const tokenFaucet = m.contract("TokenFaucet", [pokerToken]);

  // 部署主游戏合约 PokerGame
  // 由于 PokerGame 继承了多个合约，我们只需要部署最顶层的合约
  const pokerGame = m.contract("PokerGame");

  // 设置 TokenFaucet 为 PokerToken 的铸币者
  // 这需要在 PokerToken 合约中添加一个方法来设置铸币权限
  // 如果 PokerToken 没有这样的方法，可以考虑在合约中添加
  // 这里假设 PokerToken 有一个 transferOwnership 方法
  m.call(pokerToken, "transferOwnership", [tokenFaucet]);

  // 返回所有部署的合约，以便在其他模块中使用
  return {
    pokerToken,
    tokenFaucet,
    pokerGame
  };
});
