// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//version, from MIgrations.sol
contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        //0.4.2 이후 payable필요 트랜잭션 하려면
        bytes1 challenges;
    }
    //선형큐
    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 private _pot;
    bool private mode = false; //false:use answer for test, true: use real block hash
    bytes32 public answerForTest;

    uint256 internal constant BLOCK_LIMIT = 256;
    uint256 internal constant BET_BLOCK_INTERVAL = 3;
    uint256 internal constant BET_AMOUNT = 5 * 10**15;
    //enum object 순서 번호로 리턴

    enum BlockStatus {
        Checkable,
        NotRevealed,
        BlockLimitPassed
    }
    enum BettingResult {
        Win,
        Draw,
        Fail
    }
    event BET(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        uint256 answerBlockNumber
    );
    event WIN(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        bytes1 answer,
        uint256 answerBlockNumber
    );
    event DRAW(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        bytes1 answer,
        uint256 answerBlockNumber
    );
    event FAIL(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        bytes1 answer,
        uint256 answerBlockNumber
    );
    event REFUND(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        uint256 answerBlockNumber
    );

    //public 이면 자동으로 getter
    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    //betting 과 정답체크 동시 되도록하는 함수 (없을시 운영자가 해줘야 함)
    /**
     * @dev 베팅과 정답 체크를 한다. 유저는 0.005ETH롤 보내야 하고, 베팅을 1byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 disribute 함수에서 해결됨
     * @param challenges 유저가 베팅하는 글자
     * @return 함수 수행여부 확인 bool
     */
    function betAndDistribute(bytes1 challenges)
        public
        payable
        returns (bool result)
    {
        bet(challenges);
        distribute();
        return true;
    }

    //Bet
    /**
     * @dev 베팅을 한다. 유저 0.005 eth 보낸 후, 베팅용 1byte 글자를 보냄
     * 큐에 저장된 베팅 정보는 이후 disribute 함수에서 해결됨
     * @param challenges 유저가 베팅하는 글자
     * @return 함수 수행여부 확인 bool
     */
    function bet(bytes1 challenges) public payable returns (bool result) {
        // check the proper ether is sent
        require(msg.value == BET_AMOUNT, "Not enought ETH");
        // truffle 테스트시 메시지 노출

        //push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");
        //emit event
        emit BET(
            _tail - 1,
            msg.sender,
            msg.value,
            challenges,
            block.number + BET_BLOCK_INTERVAL
        );
        //emit : 375gas, 375/per parameter, parameter save 8 gas per byte = about 5000 gas
        return true;
    }

    //save the bet to the queue

    // Distribute
    /**
     * @dev 베팅결과 확인하고 팟 머니 분배
     * 정답실패:팟머니 축척, 정답:팟머니획득, 한글자 정답 또는 확인불가:베팅금액만 획득
     */
    function distribute() public {
        // 큐에 저장된 베팅 정보 ex : head 3 4 5 6 7 8 tail
        // 해시 확인 불가 경우 1. 아직 마이닝 안 됨, 2. 너무 오래되어 256 초과
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;
        for (cur = _head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            //Checkable:block.number > answerBlockNumber && block.number - BLOCK_LIMIT <  answerBlockNumber
            if (currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(
                    b.answerBlockNumber
                );
                currentBettingResult = isMatch(
                    b.challenges,
                    // blockhash(b.answerBlockNumber)
                    answerBlockHash
                );
                // if win, bettor gets pot
                if (currentBettingResult == BettingResult.Win) {
                    //transfer pot
                    transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    //pot=0
                    //transfer 이외 펑션 경우 _pot=0을 먼저 선언, pot은 반드시 0이 되어야 함으로
                    _pot = 0;

                    //emit WIN
                    emit WIN(
                        cur,
                        b.bettor,
                        transferAmount,
                        b.challenges,
                        answerBlockHash[0],
                        b.answerBlockNumber
                    );
                }
                // if fail, bettor's money goes pot
                if (currentBettingResult == BettingResult.Fail) {
                    //pot=pot+BET_AMOUNT
                    _pot += BET_AMOUNT;
                    //emit FAIL
                    emit FAIL(
                        cur,
                        b.bettor,
                        0,
                        b.challenges,
                        answerBlockHash[0],
                        b.answerBlockNumber
                    );
                }
                // if draw, refund bettor's money
                if (currentBettingResult == BettingResult.Draw) {
                    //transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(
                        b.bettor,
                        BET_AMOUNT
                    );
                    // emit DRAW
                    emit DRAW(
                        cur,
                        b.bettor,
                        transferAmount,
                        b.challenges,
                        answerBlockHash[0],
                        b.answerBlockNumber
                    );
                }
            }
            //Not Revealed:block.number <= answerBlockNumber
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            //Block Limit Passed : block.number >= answerBlockNumber + BLOCK_LIMIT
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                //refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                //emit refund
                emit REFUND(
                    cur,
                    b.bettor,
                    transferAmount,
                    b.challenges,
                    b.answerBlockNumber
                );
            }
            //check the answer
            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount)
        internal
        returns (uint256)
    {
        // uint256 fee = amount / 100;
        //for test, 0
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;
        //transfer to addr
        addr.transfer(amountWithoutFee);
        //transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer)
        public
        returns (
            // view
            bool result
        )
    {
        require(
            msg.sender == owner,
            "Only owner can set the answer forr test mode"
        );
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber)
        internal
        view
        returns (bytes32 answer)
    {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
@dev 배팅글자와 정답 확인
@param challenges 베팅글자
@param answer 블럭해시
@return 정답결과
 */
    function isMatch(bytes1 challenges, bytes32 answer)
        public
        pure
        returns (BettingResult)
    {
        // challenges 0xab
        //answer 0xab...ff 32 bytes
        bytes1 c1 = challenges;
        bytes1 c2 = challenges;
        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        //Get first number
        // shfting(move byte padding 0)
        c1 = c1 >> 4; //0xab > 0x0a
        c1 = c1 << 4; //0x0a > 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;
        //Get Second Number
        c2 = c2 << 4; //0xab > 0xb0
        c2 = c2 >> 4; //0xab > 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }
        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber)
        internal
        view
        returns (BlockStatus)
    {
        if (
            block.number > answerBlockNumber &&
            block.number < BLOCK_LIMIT + answerBlockNumber
        ) {
            // return 1;
            return BlockStatus.Checkable;
        }

        if (block.number <= answerBlockNumber) {
            // return 2;
            return BlockStatus.NotRevealed;
        }
        if (block.number >= answerBlockNumber + BLOCK_LIMIT) {
            // return 3;
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
        //for safety
    }

    // check the answer

    function getBetInfo(uint256 index)
        public
        view
        returns (
            uint256 answerBlockNumber,
            address bettor,
            bytes1 challenges
        )
    {
        //매핑펑션  모두 불러올 수는 있으나 0으로 초기화된 상태
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20 byte
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; //32 byte, 20000gas
        b.challenges = challenges; // byte, 20000gas

        _bets[_tail] = b;
        _tail++; //32byte, 20000gas
        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        //gas refund : delete, 상태데이터를 그냥 가져오기만 할때 불필요값은 delete
        delete _bets[index];
        return true;
    }
}
