# lottery dapp tutorial

: project for loterry smart contract

# env

nodejs install
npm -g install truffle@5.0.2
framework
truffle version
ganache-cli :블록체인 테스트 툴
npm -g install ganache-cli
ganache-cli
vscode extension: solidity(juan blanco)
metamask

---

truffle version
truffle init

---

dir구조
contract 스마트컨트랙트
migration 배포
test 유닛 인티 테스트
-solidity, js external test -주로 js 테스트
--
truffle compile
-build dir generated
-bytecode 실제 블록체인에 배포되는 코드

---

ganache-cli -d -m tutorial니모닉
-truffle config 세팅
truffle migrate -배포
truffle migrate --reset -재배포
앞에 번호 이미 배포된게 있으면 다음부터 실행되므로
truffle console
web3
eth = web3.eth
eth.getAccounts()
Lottery.address
-build.Lottery.json 의 주소
Lottery.deployed().then(function(instance){lt=instance})
lt -배포된 로터리의 인스턴스가 lt에 담김
lt.abi
-abi:인터페이스
lt.owner()
eth.getAccounts() -트러플은 0번 계정 배포에 사용
lt.getSomeValue()
-BN빅넘버
truffle test
truffle test test/lottery.test.js
--web3.eth.getBalance(Lottery.address)

#dapp 설계
지갑관리 -컨트랙트 접근 권한, 온라인 여부, 멀티시그
아키텍처
-front/server-front,유연한 대처 가능 중요한 데이터만 컨트랙트에서
코드 
-코드 실행에는 돈이든다 
-권한관리 
-비즈니스 로직 업데이트:딜리게이트콜, 컨트랙트 교체 
-데이터 마이그레이션:다른 스마트컨트랙트로 이동이 어렵기 때문에 저장된 데이터를 어떻게 옮길지, 저장소용과 컨트롤러 컨트랙트 분리할지, 프리즈시키고 이동하는 방법도
운영
public:네트워크
private:세팅, 합의방법(poa 순회권한)

#앱 내용
3다음 블록해쉬의 첫 두글자 맞추기
최근 256블럭만 결과 확인 가능
결과가 나왔을 때만 유저가 보낸돈을 팟머니에 저장
여러명 맞출경우 가장 먼저 맞춘 사람에게
두 글자 중 하나만 맞추면 보낸 금액 만큼만 반환
결과 검증 불가시 보낸 금액 반환(블럭해시를 컨트랙트에서 확인할 수 없는 경우)

#

https://docs.soliditylang.org/en/develop/units-and-global-variables.html?highlight=blocknumber#block-and-transaction-properties
hash of the given block when blocknumber is one of the 256 most recent blocks; otherwise returns zero

외부에서 랜덤 시드를 변경하든지, 완전한 랜덤 해시 가능한가의 문제

truffle compile
truffle migrate --reset

open zeppelin solidity 라이브러리 모음
-test helper
https://github.com/OpenZeppelin/openzeppelin-test-helpers/tree/master/src

# npm i chai

---

이더리움 수수료
-gas(gasLimit)
--tx 안에서의 gasLimit 으로 일단 한정해서 생각
-gasPrice
-ETH -수수료 = gas(21000) * gasPrice(10gwei=10\*\*9wei)
-21000*000000000 wei = 0.00021
-1ETH = 10 \*\* 18 wei

gas 계산

- 32byte 새로저장 == 20000 gas
  -- 블록체인에서 가장 가스 많이 드는 연산은 저장공간 늘리는 연산
  -- 한 tx에서 실행할 수 있는 가스 제한 있음, 블럭가스리밋 8,000,000 가스 (tx 최대 가스리밋)

- 32byt를 기존변수에 있는 값으로 바꿀 때 = 5000 gas
  기존 변수를 초기화해서 더 쓰지 않을 때 (포인터해제 유사) 1000 gas return

truffle console
Lottery.deployed().then(function(instance){lt=instance})
web3.eth.getAccounts()
let bettor = '0xF76c9B7012c0A3870801eaAddB93B6352c8893DB'
lt.bet("0xab",{from:bettor, value:5000000000000000, gas:300000})

-실행시 로그
gasUsed: 89276,
gasUsed: 74276, -역산
기본 21000 + 60000 + event(5000~) = 86000~ gas
두번째 tx에서는 \_tail 값을 바꾸는 연산, 5000 가스만 소모 : 20000 > 5000 gas (15000 감소)
컨트랙트 가스 줄이려면 몇 바이트를 어디에 저장하는지 + 이벤트 소모 가스량 고려

---

web3.eth.getBlockNumber()
web3.eth.getBlock(120)
test 시 블록해시 발췌

---

컨트랙트에서 이더전송 방법
call-이더 전송 뿐 아니라 동시에 펑션 콜, 위험, 외부 컨트랙트 관련 위험 / send-실패시 false 리턴 / transfer-실패시 컨트랙트 자체를 fail 가장 안전

---

ganache-cli
https://github.com/trufflesuite/ganache

tx생성시 블럭 채굴됨, 또는 rpc call evm_mine
https://github.com/trufflesuite/ganache-cli-archive

evm_mine : Force a block to be mined. Takes one optional parameter, which is the timestamp a block should setup as the mining time. Mines a block independent of whether or not mining is started or stopped.

---

스마트컨트랙트 오픈 되는 것을 기본으로 관습화 되어 있다
설계, 테스트코드, 정적 분석 등
테스트는 아무리 많아도 지나치지 않다
만약 상황 대처 방법 미리 마련해야 함.
참고-패리티 멀티시그 버그, 솔리디티 개발자

---
npm install create-react-app@4.0.0 --save
  npm install create-react-app -g
create-react-app lottery-react-web
cd lottery-react-web
yarn start
yarn add web3

---
react 부분 구버전, 추가 설명만 기입
https://medium.com/metamask/https-medium-com-metamask-breaking-change-injecting-web3-7722797916a8
메타마스크 연동 방법은 항상 최신 방법 참고 해야함
legacy web3객체, tobe ethereum 객체
build.contracts.Lottery.json 빌드생성된 json을 abi 객체로 선언 (줄바꿈 지우고 복붙)

let accounts = await this.web3.eth.getAccounts();
this.accounts - accounts[0];
this.lotteryContract = new this.web3.eth.Contract(lotteryANI, lotteryAddress);

let pot = await this.lotteryContract.method.getPot().call();
let potString = this.web3.utils.fromWei(pot.toString(),'ether')
//call 상태 read만 일 때
let owner = await this.lotteryContract.methods.owner().call()
this.lotteryContract.methods.betAnddistribute('0xcd').send({from:this.account, value:50000000000, gas:30000})
//상태 업데이트

let events = await this.lotteryContract.getPastEvents('BET',{fromBlock:0, toBlock:'latest'})
//로그 read

--- dapp 데이터관리
컨트랙트 직접 call, 더 이벤트보다 더 느림, batch read call
이벤트로그
  폴링
  웹소켓
1. init 동시 past event들을 가져온다
2. ws으로 geth또는 infura 연결
3. ws으로 원하는 이벤트를 subscribe 한다
https://web3js.readthedocs.io/en/v1.5.2/web3-eth-subscribe.html#subscribe-logs
  웹소켓 사용할 수 없다면 폴링.
4. 금액 큰 서비스 > 블락 컨펌 확인 btc6 eth20 컨펌, 서비스 안정성

---
yarn add bootstrap
import 'bootstrap/dist/css/bootstrap.css'

www.w3schools.com/bootstrap4/bootstrap_cards.asp
https://en.wikipedia.org/wiki/Standard_52-card_deck

input
앞 8자리 함수시그니쳐
