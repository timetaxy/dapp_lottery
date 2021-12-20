const Lottery = artifacts.require("Lottery");
const assertRevert = require('./assertRevert')
const expectEvent = require('./expectEvent')
//mocha를 컨트랙트용으로
contract("Lottery", function ([deployer, user1, user2]) {
  //accounts 순서대로 계정 입력됨
  let lottery;
  let betAmount = 5 * 10 ** 15;
  let betAmountBN = new web3.utils.BN('5000000000000000');
  let bet_block_interval = 3;

  beforeEach(async () => {
    // console.log("Before each");
    lottery = await Lottery.new();
    //이렇게 배포하고 하기를 추천
  });
  //   it("Basic test", async () => {
  //     console.log("Basic test");
  //     let owner = await lottery.owner();
  //     console.log(`owner:${owner}`);
  //   });

  //특정 테스트만 it.only
  it("getPot should return current pot", async () => {
    //   it.only("getPot should return current pot", async () => {
    let pot = await lottery.getPot();
    assert.equal(pot, 0);
  });

  describe("Bet", function () {
    it('should fail when the bet money is not 0.005 ETH', async () => {
      //Fail tx
      await assertRevert(lottery.bet('0xab', { from: user1, value: 5000000000000000 }))


      //tx object {chainId, value, to,from,gas(Limit),gasPrice}
    })
    it("should put the bet to the bet queue with 1bet", async () => {
      //bet
      // 10 * 5 * 10 ^15
      let receipt = await lottery.bet('0xab', { from: user1, value: betAmount })
      //contractAddress 필드는 해당 트랜잭션이 컨트랙트 create 일때  
      console.log(receipt);
      let pot = await lottery.getPot();
      assert.equal(pot, 0);

      //check contract balance == 0.005
      let contractBalance = await web3.eth.getBalance(lottery.address);
      //truffle 은 web3 바로 사용 가능
      assert.equal(contractBalance, betAmount);

      //check bet info
      let currentBlockNumber = await web3.eth.getBlockNumber();
      let bet = await lottery.getBetInfo(0)

      assert.equal(bet.answerBlockNumber, currentBlockNumber + bet_block_interval);
      assert.equal(bet.bettor, user1);
      assert.equal(bet.challenges, '0xab');

      //check log
      // console.log(receipt)
      await expectEvent.inLogs(receipt.logs, 'BET')

    });
  });

  describe('isMatch', function () {
    let blockHash = '0x07d1a5de9fd2a240b7193a2943f20f754aa6a239e6669f1befdd0d93a1eb8477';
    it('should be BettingResult.win when two charactors match', async () => {
      let matchingResult = await lottery.isMatch('0x07', blockHash);
      assert.equal(matchingResult, 0);
    })
    it('should be BettingResult.draw when two charactors match', async () => {
      let matchingResult = await lottery.isMatch('0xa7', blockHash);
      assert.equal(matchingResult, 1);
      matchingResult = await lottery.isMatch('0x0a', blockHash);
      assert.equal(matchingResult, 1);
    })
    it('should be BettingResult.fail when two charactors match', async () => {
      let matchingResult = await lottery.isMatch('0xaa', blockHash);
      assert.equal(matchingResult, 2);
    })
  })

  describe('Disribute', () => {
    describe('When the answer is checkable', () => {
      it('should transfer the pot when the answer was matched', async () => {
        //두 글자 맞을 때
        await lottery.setAnswerForTest('0x07d1a5de9fd2a240b7193a2943f20f754aa6a239e6669f1befdd0d93a1eb8477', { from: deployer })
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//1>4
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//2>5
        await lottery.betAndDistribute('0x07', { from: user1, value: betAmount })//3>6 //bet3 > res6
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//4>7
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//5>8
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//6>9

        let potBefore = await lottery.getPot();//==0.01ETH
        let user1BalanceBefore = await web3.eth.getBalance(user1);

        let receipt7 = await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//7>10 //reward to user1
        let potAfter = await lottery.getPot();//==0
        let user1BalanceAfter = await web3.eth.getBalance(user1);//==before+0.015 ETH
        //pot 변화량
        console.log(potBefore);
        assert.equal(potBefore, toString(), new web3.utils.BN('1000000000000000').toString());
        assert.equal(potAfter, toString(), new web3.utils.BN('0').toString());

        //user(winner) 밸런스 체크
        user1BalanceBefore = new web3.utils.BN(userBalanceBefore)
        assert.equal(user1BalanceBefore.add(potBefore).add(betAmountBN).toString(), new web3.utils.BN(user1BalanceAfter).toString())


      })
      it('should transfer the amount of bet when a single character matched with the answer', async () => {
        //한글자 일치
        await lottery.setAnswerForTest('0x07d1a5de9fd2a240b7193a2943f20f754aa6a239e6669f1befdd0d93a1eb8477', { from: deployer })
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//1>4
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//2>5
        await lottery.betAndDistribute('0xa7', { from: user1, value: betAmount })//3>6 //bet3 > res6
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//4>7
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//5>8
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//6>9

        let potBefore = await lottery.getPot();//==0.01ETH
        let user1BalanceBefore = await web3.eth.getBalance(user1);

        let receipt7 = await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//7>10 //reward to user1
        let potAfter = await lottery.getPot();//==0.01
        let user1BalanceAfter = await web3.eth.getBalance(user1);//==before+0.005 ETH
        //pot 변화량
        console.log(potBefore);
        assert.equal(potBefore, toString(), potAfter.toString());

        //user(winner) 밸런스 체크
        user1BalanceBefore = new web3.utils.BN(userBalanceBefore)
        assert.equal(user1BalanceBefore.add(betAmountBN).toString(), new web3.utils.BN(user1BalanceAfter).toString())
      })
      it('should get the ether of user when the answer does not match at all', async () => {
        //틀림

        await lottery.setAnswerForTest('0x07d1a5de9fd2a240b7193a2943f20f754aa6a239e6669f1befdd0d93a1eb8477', { from: deployer })
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//1>4
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//2>5
        await lottery.betAndDistribute('0xa7', { from: user1, value: betAmount })//3>6 //bet3 > res6
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//4>7
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//5>8
        await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//6>9

        let potBefore = await lottery.getPot();//==0.01ETH
        let user1BalanceBefore = await web3.eth.getBalance(user1);

        let receipt7 = await lottery.betAndDistribute('0xef', { from: user2, value: betAmount })//7>10 //reward to user1
        let potAfter = await lottery.getPot();//==0.015
        let user1BalanceAfter = await web3.eth.getBalance(user1);//==before
        //pot 변화량
        console.log(potBefore);
        assert.equal(potBefore.add(betAmountBN).toString(), potAfter.toString());

        //user(winner) 밸런스 체크
        user1BalanceBefore = new web3.utils.BN(userBalanceBefore)
        assert.equal(user1BalanceBefore.toString(), new web3.utils.BN(user1BalanceAfter).toString())
      })

    })

    describe.only('When the answer is not revealed(Not Mined)', async () => {
      let user1BalanceBefore = await web3.eth.getBalance(user1);
      let potBefore = await lottery.getPot();
      let receipt = await lottery.betAndDistribute('0xa7', { from: user1, value: betAmount })
      console.log(receipt)
      let user1BalanceAfter = await web3.eth.getBalance(user1);
      let potAfter = await lottery.getPot();

      assert.equal(potBefore.add(betAmountBN).toString(), potAfter.toString());
      assert.equal(user1BalanceBefore.toString(), new web3.utils.BN(user1BalanceAfter).toString())

    })
    describe('When the answer is not revealed(block limit is passed)', async () => {
      let user1BalanceBefore = await web3.eth.getBalance(user1);
      let potBefore = await lottery.getPot();
      let receiptBet = await lottery.bet('0x11', { from: user1, value: betAmount });
      for (let index = 0; index < 256 + 1; index++) {
        await lottery.distribute({ from: user1, value: betAmount });
      }
      let receiptDist = await lottery.distribute({ from: user1, value: betAmount })
      let user1BalanceAfter = await web3.eth.getBalance(user1);
      let potAfter = await lottery.getPot();
      assert.equal(user1BalanceBefore.toString(), new web3.utils.BN(user1BalanceAfter).toString())
      assert.equal(potBefore.add(betAmountBN).toString(), potAfter.toString());
    })
  })
});
