var StandardGame = artifacts.require("StandardGame");
var StringUtils = artifacts.require("StringUtils");

module.exports = function (deployer) {
    deployer.deploy(StringUtils);
    deployer.link(StringUtils, StandardGame);

    // Deploy chain chess with maxGames constructor argument
    deployer.deploy(StandardGame, 6);
};
