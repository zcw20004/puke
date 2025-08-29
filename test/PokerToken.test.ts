import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { parseEther } from "viem";

describe("PokerToken合约测试", async function () {
  const { viem } = await network.connect();
  
  let pokerToken: any;
  let tokenFaucet: any;
  let accounts: any[];

  beforeEach(async function () {
    // 获取测试账户
    accounts = await viem.getWalletClients();
    
    // 部署PokerToken合约
    const initialSupply = 1000000n; // 1,000,000 tokens
    pokerToken = await viem.deployContract("contracts/token/PokerToken.sol:PokerToken", [initialSupply]);
    
    // 部署TokenFaucet合约
    tokenFaucet = await viem.deployContract("contracts/token/TokenFaucet.sol:TokenFaucet", [
      pokerToken.address,
      accounts[0].account!.address // token owner
    ]);
  });

  describe("基本ERC20功能测试", function () {
    it("应该有正确的名称和符号", async function () {
      const name = await pokerToken.read.name();
      const symbol = await pokerToken.read.symbol();
      const decimals = await pokerToken.read.decimals();
      
      assert.equal(name, "Poker Token");
      assert.equal(symbol, "PKR");
      assert.equal(decimals, 18);
    });

    it("应该有正确的初始供应量", async function () {
      const totalSupply = await pokerToken.read.totalSupply();
      const balance = await pokerToken.read.balanceOf([accounts[0].account!.address]);
      
      const expectedSupply = 1000000n * 10n**18n; // 1M tokens with 18 decimals
      assert.equal(totalSupply, expectedSupply);
      assert.equal(balance, expectedSupply);
    });

    it("应该能够转账代币", async function () {
      const transferAmount = parseEther("1000");
      
      await pokerToken.write.transfer([accounts[1].account!.address, transferAmount]);
      
      const balance = await pokerToken.read.balanceOf([accounts[1].account!.address]);
      assert.equal(balance, transferAmount);
    });

    it("应该能够mint代币", async function () {
      const mintAmount = parseEther("5000");
      const initialBalance = await pokerToken.read.balanceOf([accounts[1].account!.address]);
      
      await pokerToken.write.mint([accounts[1].account!.address, mintAmount]);
      
      const newBalance = await pokerToken.read.balanceOf([accounts[1].account!.address]);
      assert.equal(newBalance - initialBalance, mintAmount);
    });
  });

  describe("TokenFaucet功能测试", function () {
    it("应该能够向水龙头mint代币", async function () {
      const mintAmount = parseEther("10000");
      
      // PokerToken的owner直接mint给faucet
      await pokerToken.write.mint([tokenFaucet.address, mintAmount]);
      
      const faucetBalance = await tokenFaucet.read.getFaucetBalance();
      assert.equal(faucetBalance, mintAmount);
    });

    it("应该能够从水龙头申请代币", async function () {
      // 先向水龙头mint一些代币
      const mintAmount = parseEther("10000");
      await pokerToken.write.mint([tokenFaucet.address, mintAmount]);
      
      // 申请代币
      const initialBalance = await pokerToken.read.balanceOf([accounts[1].account!.address]);
      await tokenFaucet.write.claimTokens({ account: accounts[1].account! });
      
      const newBalance = await pokerToken.read.balanceOf([accounts[1].account!.address]);
      const expectedIncrease = 1000n * 10n**18n; // faucetAmount = 1000 tokens
      
      assert.equal(newBalance - initialBalance, expectedIncrease);
    });

    it("应该检查冷却时间", async function () {
      // 先向水龙头mint一些代币
      const mintAmount = parseEther("10000");
      await pokerToken.write.mint([tokenFaucet.address, mintAmount]);
      
      // 第一次申请应该成功
      await tokenFaucet.write.claimTokens({ account: accounts[1].account! });
      
      // 立即再次申请应该失败
      try {
        await tokenFaucet.write.claimTokens({ account: accounts[1].account! });
        assert.fail("应该因为冷却时间而失败");
      } catch (error: any) {
        assert(error.message.includes("Still in cooldown period") || error.message.includes("revert"));
      }
    });


  });
}); 