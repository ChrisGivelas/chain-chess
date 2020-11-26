var StandardGame = artifacts.require("StandardGame");
var StringUtils = artifacts.require("StringUtils");
var Chess = artifacts.require("Chess");

module.exports = function (deployer) {
    deployer.deploy(StringUtils);
    deployer.link(StringUtils, StandardGame);

    deployer.deploy(Chess);
    deployer.link(Chess, StandardGame);

    // Deploy chain chess with maxGames constructor argument
    deployer.deploy(StandardGame, 6);
};
