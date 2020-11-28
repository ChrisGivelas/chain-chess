import { checksumAddr } from "./eth";

const PLAYER_SIDE_MAPPING = ["none", "white", "black"];

export function parseGameResponse(game) {
    const {
        gameId,
        moveHistory,
        currentTurn,
        started,
        ended,
        whiteAddress,
        blackAddress,
        winner,
        inCheck,
        moveCount,
    } = game;

    let mappedTurn =
        PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(currentTurn)];
    let mappedCheck = PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(inCheck)];

    let normalizedWhiteAddress = checksumAddr(whiteAddress);
    let normalizedBlackAddress = checksumAddr(blackAddress);
    let normalizedWinnerAddress = checksumAddr(winner);

    return {
        gameId: window.web3.utils.toDecimal(gameId),
        moveHistory,
        currentTurn: mappedTurn,
        started,
        ended,
        white: {
            address: normalizedWhiteAddress,
            side: "white",
            isPlayersTurn: mappedTurn === "white",
            isInCheck: mappedCheck === "white",
            isWinner: normalizedWhiteAddress === normalizedWinnerAddress,
        },
        black: {
            address: normalizedBlackAddress,
            side: "black",
            isPlayersTurn: mappedTurn === "black",
            isInCheck: mappedCheck === "black",
            isWinner: normalizedBlackAddress === normalizedWinnerAddress,
        },
        winner: normalizedWinnerAddress,
        inCheck: mappedCheck,
        moveCount: window.web3.utils.toDecimal(moveCount),
    };
}

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
