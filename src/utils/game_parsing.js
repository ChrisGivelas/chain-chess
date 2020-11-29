import { checksumAddr } from "./eth";

export const PLAYER_SIDE_MAPPING = ["None", "White", "Black"];

export const parseBasicInfoResponse = (basicInfo) => {
    const {
        gameId,
        moveHistory,
        whiteAddress,
        blackAddress,
        currentTurn,
        started,
    } = basicInfo;

    return {
        gameId: window.web3.utils.toDecimal(gameId),
        moveHistory,
        white: {
            address: checksumAddr(whiteAddress),
        },
        black: {
            address: checksumAddr(blackAddress),
        },
        currentTurn:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(currentTurn)],
        started,
    };
};

export const parseEndGameInfoResponse = (endGameInfo) => {
    const { inCheck, ended, winner, moveCount } = endGameInfo;

    return {
        inCheck: PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(inCheck)],
        ended,
        winner: checksumAddr(winner),
        moveCount: window.web3.utils.toDecimal(moveCount),
    };
};

export const parseGameResponse = (game) => {
    const basicInfo = parseBasicInfoResponse(game);
    const endGameInfo = parseEndGameInfoResponse(game);
    return {
        ...basicInfo,
        ...endGameInfo,
    };
};

export function getPlayerInfoFromGame(game, side) {
    if (!game) {
        return undefined;
    }

    return {
        address: game[`${side}Address`],
        side: side.toUpperCase(),
        isPlayersTurn: game.currentTurn === side.toUpperCase(),
        isWinner: game[`${side}Address`] === game.winnerAddress,
    };
}

const parse_BN_array = (bnArray) => bnArray.map(window.web3.utils.toDecimal);

export function parsePlayerProfileResponse(profile) {
    const { activeGames, completedGames, wins, losses } = profile;

    return {
        activeGames: parse_BN_array(activeGames),
        completedGames: parse_BN_array(completedGames),
        wins: window.web3.utils.toDecimal(wins),
        losses: window.web3.utils.toDecimal(losses),
    };
}
