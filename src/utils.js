import Web3 from "web3";
import TruffleContract from "@truffle/contract";

export const updateWeb3AndReturnWeb3Provider = () => {
    var web3Provider;
    if (typeof window.web3 !== "undefined") {
        web3Provider = window.web3.currentProvider;
    } else {
        web3Provider = new Web3.providers.HttpProvider("http://localhost:8545");
    }

    window.web3 = new Web3(web3Provider);

    return web3Provider;
};

export const getStandardGameContract = (web3Provider) => {
    var StandardGameArtifact = require("./contracts/StandardGame.json");
    var StandardGameContract = TruffleContract(StandardGameArtifact);
    StandardGameContract.setProvider(web3Provider);

    return StandardGameContract;
};
