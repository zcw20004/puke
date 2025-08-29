import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// 定义初始代币供应量
const INITIAL_TOKEN_SUPPLY = 1000000n; // 1,000,000 tokens

export default buildModule("PokerGameModule", (m) => {
  // 部署工具库
  // 注意：库不需要显式部署，它们会在使用它们的合约部署时自动链接

  // 获取部署者账户
  const deployer = m.getAccount(0);

  // 部署 PokerToken
  const pokerToken = m.contract("PokerToken", [INITIAL_TOKEN_SUPPLY]);

  // 部署 TokenFaucet，需要传入token地址和token所有者地址
  const tokenFaucet = m.contract("TokenFaucet", [pokerToken, deployer]);

  // 部署主游戏合约 PokerGame
  // 由于 PokerGame 继承了多个合约，我们只需要部署最顶层的合约
  const pokerGame = m.contract("PokerGame");

  // 为水龙头mint一些初始代币（可选）
  // PokerToken的所有者可以mint代币给TokenFaucet
  const initialFaucetSupply = 100000n * 10n**18n; // 100,000 tokens
  m.call(pokerToken, "mint", [tokenFaucet, initialFaucetSupply]);

  // 返回所有部署的合约，以便在其他模块中使用
  return {
    pokerToken,
    tokenFaucet,
    pokerGame
  };
});
