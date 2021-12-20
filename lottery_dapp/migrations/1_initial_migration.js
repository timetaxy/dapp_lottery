const Migrations = artifacts.require("Migrations");
module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
//1 migration 관련 파일은 그냥두고 2 부터 작성하길 추천
