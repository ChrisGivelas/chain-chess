var ChainChess = artifacts.require("ChainChess");

module.exports = function(deployer) {
    // Deploy chain chess with maxGames constructor argument
    deployer.deploy(ChainChess, 6);
};