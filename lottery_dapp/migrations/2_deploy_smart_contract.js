const Lottery = artifacts.require("Lottery");
//1_initial_migration 복사생성
//build folder 안의 migrations 가져옴, 아래 deployer가 배포
//배포 주소는 truffle-config에 세팅
module.exports = function (deployer) {
  deployer.deploy(Lottery);
};
