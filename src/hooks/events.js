import { useState, useEffect } from "react";

export function useMovePieceSubscription(gameId) {
    const [moveHistory, setMoveHistory] = useState("");

    useEffect(() => {
        window.cc_standardGameContract.deployed().then((instance) => {
            instance.MovePiece(
                {
                    filter: { gameId: gameId },
                    fromBlock: 0,
                },
                function (err, e) {
                    const newMoveHistory = e.returnValues.moveHistory;
                    setMoveHistory(newMoveHistory);
                }
            );
        });
    }, [gameId]);

    return moveHistory;
}
