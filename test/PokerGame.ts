import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { parseEther } from "viem";

describe("PokerGame合约测试", async function () {
  const { viem } = await network.connect();
  
  let pokerGame: any;
  let accounts: any[];

  beforeEach(async function () {
    // 获取测试账户
    accounts = await viem.getWalletClients();
    
    // 部署合约 - 指定完整路径以避免歧义
    pokerGame = await viem.deployContract("contracts/PokerGame.sol:PokerGame");
  });

  describe("基本游戏功能测试", function () {
    it("应该能够成功创建游戏", async function () {
      const initialChips = 1000n; // INITIAL_CHIPS = 1000 wei
      
      const tx = await pokerGame.write.createGame({ value: initialChips });
      await viem.assertions.emit(tx, pokerGame, "GameCreated");

      // 验证游戏状态
      const gameInfo = await pokerGame.read.getGame([1n]);
      assert.equal(gameInfo[0], 1n); // gameId
      assert.equal(gameInfo[1].toLowerCase(), accounts[0].account!.address.toLowerCase()); // creator
      assert.equal(gameInfo[2], 1n); // playerCount
      assert.equal(gameInfo[3], 0n); // pot
      assert.equal(gameInfo[4], 0); // GameState.WAITING
    });

    it("筹码不足时创建游戏应该失败", async function () {
      const insufficientChips = 999n; // 小于INITIAL_CHIPS(1000)
      
      try {
        await pokerGame.write.createGame({ value: insufficientChips });
        assert.fail("应该抛出错误但没有");
      } catch (error: any) {
        assert(error.message.includes("Insufficient chips") || error.message.includes("revert"));
      }
    });

        it("玩家应该能够加入游戏", async function () {
      // 首先创建游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      // 第二个玩家加入游戏
      const joinTx = await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });
      await viem.assertions.emit(joinTx, pokerGame, "PlayerJoined");

      // 验证玩家数量增加
      const gameInfo = await pokerGame.read.getGame([gameId]);
      assert.equal(gameInfo[2], 2n); // playerCount
    });

    it("应该能够开始游戏", async function () {
      // 创建游戏并添加玩家
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      // 开始游戏
      await viem.assertions.emitWithArgs(
        pokerGame.write.startGame([gameId]),
        pokerGame,
        "GameStarted",
        [gameId]
      );

      // 验证游戏状态变为BETTING
      const gameInfo = await pokerGame.read.getGame([gameId]);
      assert.equal(gameInfo[4], 2); // GameState.BETTING
    });

        it("应该能够下注", async function () {
      // 准备游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      // 下注
      const betAmount = 100n; // MIN_BET = 100
      const betTx = await pokerGame.write.placeBet([gameId, betAmount]);
      await viem.assertions.emit(betTx, pokerGame, "BetPlaced");

      // 验证奖池增加
      const gameInfo = await pokerGame.read.getGame([gameId]);
      assert.equal(gameInfo[3], betAmount); // pot
    });

        it("应该能够弃牌", async function () {
      // 准备游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      // 第二个玩家弃牌
      await pokerGame.write.fold([gameId], { account: accounts[1].account! });

      // 验证玩家变为非活跃状态
      const playerInfo = await pokerGame.read.getPlayerInfo([gameId, accounts[1].account!.address]);
      assert.equal(playerInfo[2], false); // isActive

      // 游戏应该结束，第一个玩家获胜
      const gameInfo = await pokerGame.read.getGame([gameId]);
      assert.equal(gameInfo[4], 4); // GameState.FINISHED
      assert.equal(gameInfo[5].toLowerCase(), accounts[0].account!.address.toLowerCase()); // winner
    });

    it("应该能够查看自己的手牌", async function () {
      // 准备游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      // 查看手牌
      const cards = await pokerGame.read.getPlayerCards([gameId, accounts[0].account!.address]);
      
      // 验证返回3张牌
      assert.equal(cards.length, 3);
      // 验证牌值和花色有效
      for (let i = 0; i < cards.length; i++) {
        const card = cards[i];
        // card现在是一个结构体，根据ABI编码可能是 {suit, rank} 或 [suit, rank]
        const suit = card.suit !== undefined ? card.suit : card[0];
        const rank = card.rank !== undefined ? card.rank : card[1];
        
        assert(suit >= 0 && suit <= 3, `Invalid suit: ${suit}`); // 花色 0-3  
        assert(rank >= 1 && rank <= 13, `Invalid rank: ${rank}`); // 点数 1-13
      }
    });

        it("不能查看其他玩家的手牌", async function () {
      // 准备游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      // 尝试查看其他玩家手牌应该失败
      try {
        await pokerGame.read.getPlayerCards([gameId, accounts[1].account!.address]);
        assert.fail("应该抛出错误但没有");
      } catch (error: any) {
        assert(error.message.includes("Can only view own cards") || error.message.includes("revert"));
      }
    });

    it("应该能够摊牌并确定获胜者", async function () {
      // 准备游戏
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      // 下注增加奖池
      const betAmount = 100n;
      await pokerGame.write.placeBet([gameId, betAmount]);
      await pokerGame.write.placeBet([gameId, betAmount], { account: accounts[1].account! });

      // 摊牌
      await viem.assertions.emit(
        pokerGame.write.showdown([gameId]),
        pokerGame,
        "GameEnded"
      );

      // 验证游戏结束
      const gameInfo = await pokerGame.read.getGame([gameId]);
      assert.equal(gameInfo[4], 4); // GameState.FINISHED
      assert.notEqual(gameInfo[5], "0x0000000000000000000000000000000000000000"); // 有获胜者
    });
  });

  describe("错误条件测试", function () {
    it("非创建者不能开始游戏", async function () {
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      try {
        await pokerGame.write.startGame([gameId], { account: accounts[1].account! });
        assert.fail("应该抛出错误但没有");
      } catch (error: any) {
        assert(error.message.includes("Not game creator") || error.message.includes("revert"));
      }
    });

    it("下注金额低于最小值应该失败", async function () {
      const initialChips = 1000n;
      await pokerGame.write.createGame({ value: initialChips });
      const gameId = 1n;

      await pokerGame.write.joinGame([gameId], { 
        value: initialChips,
        account: accounts[1].account!
      });

      await pokerGame.write.startGame([gameId]);

      const smallBet = 99n; // 小于MIN_BET(100)
      
      try {
        await pokerGame.write.placeBet([gameId, smallBet]);
        assert.fail("应该抛出错误但没有");
      } catch (error: any) {
        assert(error.message.includes("Bet too small") || error.message.includes("revert"));
      }
    });

    it("查询不存在的游戏应该失败", async function () {
      try {
        const result = await pokerGame.read.getGame([999n]);
        // 如果没有抛出错误，检查返回的creator是否为零地址
        assert.equal(result[1], "0x0000000000000000000000000000000000000000", "不存在的游戏creator应该为零地址");
      } catch (error: any) {
        // 如果抛出错误也是可以接受的
        assert(error.message.includes("Game does not exist") || error.message.includes("revert"));
      }
    });
  });
}); 