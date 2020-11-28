import TruffleContract from "@truffle/contract";
import {
    parseGameResponse,
    parsePlayerProfileResponse,
} from "./utils/game_parsing";
import { getRankIndexFromVal, getFileIndexFromVal } from "./utils/chess";

export const getStandardGameContract = (web3Provider) => {
    var StandardGameArtifact = require("./contracts/StandardGame.json");
    var StandardGameContract = TruffleContract(StandardGameArtifact);
    StandardGameContract.setProvider(web3Provider);

    return StandardGameContract;
};

export const getGameByGameId = (connectedWalletAddress, gameId) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        var basicInfoRequest = instance.getBasicInfoForGameByGameId(gameId, {
            from: connectedWalletAddress,
        });

        var endGameInfoRequest = instance.getEndgameInfoForGameByGameId(
            gameId,
            {
                from: connectedWalletAddress,
            }
        );

        return await Promise.all([basicInfoRequest, endGameInfoRequest]).then(
            ([basicInfo, endGameInfo]) => {
                var info = {
                    ...basicInfo,
                    ...endGameInfo,
                };

                return parseGameResponse(info);
            }
        );
    });
};

export const getGameByOpponent = (connectedWalletAddress, opponentAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        var basicInfoRequest = instance.getBasicInfoForGameByOpponentAddress(
            opponentAddress,
            {
                from: connectedWalletAddress,
            }
        );

        var endGameInfoRequest = instance.getEndgameInfoForGameByOpponentAddress(
            opponentAddress,
            {
                from: connectedWalletAddress,
            }
        );

        return await Promise.all([basicInfoRequest, endGameInfoRequest]).then(
            ([basicInfo, endGameInfo]) => {
                var info = {
                    ...basicInfo,
                    ...endGameInfo,
                };

                return parseGameResponse(info);
            }
        );
    });
};

export const acceptGame = (connectedWalletAddress, opponentAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.acceptGame(opponentAddress, {
            from: connectedWalletAddress,
        });
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

export const getPlayerProfile = (address) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance
            .getPlayerProfile({ from: address })
            .then(parsePlayerProfileResponse);
    });
};

export const getActiveGames = (connectedWalletAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.getActiveGames({
            from: connectedWalletAddress,
        });
    });
};

export const declareSearchingForGame = (connectedWalletAddress) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.declareSearchingForGame({
            from: connectedWalletAddress,
        });
    });
};

export const getUsersSearchingForGame = () => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.getUsersSearchingForGame();
    });
};

export const userIsSearching = (address) => {
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.userIsSearching(address);
    });
};
