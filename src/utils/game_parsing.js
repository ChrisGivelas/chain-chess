import { checksumAddr } from "./eth";

const PLAYER_SIDE_MAPPING = ["NONE", "WHITE", "BLACK"];

export function parseResultToGame(game) {
    const [
        gameId,
        moveHistory,
        currentTurn,
        started,
        ended,
        player1Address,
        player1Side,
        player2Address,
        player2Side,
        winnerAddress,
    ] = Object.values(game);

    return {
        gameId: window.web3.utils.toDecimal(gameId),
        moveHistory,
        currentTurn:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(currentTurn)],
        started,
        ended,
        player1Address: checksumAddr(player1Address),
        player1Side:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(player1Side)],
        player2Address: checksumAddr(player2Address),
        player2Side:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(player2Side)],
        winnerAddress: checksumAddr(winnerAddress),
    };
}

export function getOtherPlayersInfoFromGame(game, address) {
    if (!game) {
        return undefined;
    }

    var accessorKey =
        address === game.player1Address
            ? "player2"
            : address === game.player2Address
            ? "player1"
            : undefined;

    if (!accessorKey) return undefined;

    return {
        address: game[`${accessorKey}Address`],
        side: game[`${accessorKey}Side`],
        isPlayersTurn: game.currentTurn === game[`${accessorKey}Side`],
        isWinner: game[`${accessorKey}Address`] === game.winnerAddress,
    };
}

export function getPlayerInfoFromGame(game, address) {
    if (!game) {
        return undefined;
    }

    var accessorKey =
        address === game.player1Address
            ? "player1"
            : address === game.player2Address
            ? "player2"
            : undefined;

    if (!accessorKey) return undefined;

    return {
        address: game[`${accessorKey}Address`],
        side: game[`${accessorKey}Side`],
        isPlayersTurn: game.currentTurn === game[`${accessorKey}Side`],
        isWinner: game[`${accessorKey}Address`] === game.winnerAddress,
    };
}
