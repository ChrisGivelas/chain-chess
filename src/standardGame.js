import TruffleContract from "@truffle/contract";

export const getStandardGameContract = (web3Provider) => {
    var StandardGameArtifact = require("./contracts/StandardGame.json");
    var StandardGameContract = TruffleContract(StandardGameArtifact);
    StandardGameContract.setProvider(web3Provider);

    return StandardGameContract;
};

export const getGameByOpponent = (connectedWalletAddress, opponentAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.getGameByOpponent(opponentAddress, {
            from: connectedWalletAddress,
        });
    });
};
