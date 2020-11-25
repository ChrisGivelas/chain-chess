import TruffleContract from "@truffle/contract";
import { parseResultToGame } from "./utils/game_parsing";
import { getRankIndexFromVal, getFileIndexFromVal } from "./utils/chess";

export const getStandardGameContract = (web3Provider) => {
    var StandardGameArtifact = require("./contracts/StandardGame.json");
    var StandardGameContract = TruffleContract(StandardGameArtifact);
    StandardGameContract.setProvider(web3Provider);

    return StandardGameContract;
};

export const getGameByOpponent = (connectedWalletAddress, opponentAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance
            .getGameByOpponent(opponentAddress, {
                from: connectedWalletAddress,
            })
            .then(parseResultToGame);
    });
};

export const getGameByGameId = (connectedWalletAddress, gameId) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance
            .getGameByGameId(gameId, {
                from: connectedWalletAddress,
            })
            .then(parseResultToGame);
    });
};

export const movePiece = (
    connectedWalletAddress,
    gameId,
    sourceSquare,
    targetSquare
) => {
    const [prevFilePos, prevRankPos] = sourceSquare.split("");
    const [newFilePos, newRankPos] = targetSquare.split("");

    console.log(gameId, prevRankPos, prevFilePos, newRankPos, newFilePos);

    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.movePiece(
            gameId,
            getRankIndexFromVal(prevRankPos),
            getFileIndexFromVal(prevFilePos),
            getRankIndexFromVal(newRankPos),
            getFileIndexFromVal(newFilePos),
            {
                from: connectedWalletAddress,
            }
        );
    });
};
