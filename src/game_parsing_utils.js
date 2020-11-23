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
        player1Address,
        player1Side:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(player1Side)],
        player2Address,
        player2Side:
            PLAYER_SIDE_MAPPING[window.web3.utils.toDecimal(player2Side)],
        winnerAddress,
    };
}
