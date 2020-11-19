var StandardGame = artifacts.require("StandardGame");

module.exports = function (deployer) {
    // Deploy chain chess with maxGames constructor argument
    deployer.deploy(StandardGame, 6);
};
