import { useState, useEffect } from "react";
import { useLocation } from "react-router-dom";
import {
    gameStartedToast,
    moveTurnToast,
    checkmatedToast,
} from "../utils/toast";

export function useMovePieceSubscription(
    connectedWalletAddress,
    gameId = null
) {
    const [moveHistory, setMoveHistory] = useState("");
    const location = useLocation();

    useEffect(() => {
        let filter = { player: connectedWalletAddress };
        if (gameId !== null) {
            filter.gameId = gameId;
        }

        window.cc_standardGameContract.deployed().then((instance) => {
            instance.PieceMove(
                {
                    filter,
                    fromBlock: 0,
                },
                function (err, e) {
                    const newMoveHistory = e.returnValues.moveHistory;
                    setMoveHistory(newMoveHistory);

                    if (location.pathname.indexOf("/game") !== -1) {
                        moveTurnToast(
                            e.returnValues.gameId,
                            e.returnValues.playerMakingMove
                        );
                    }
                }
            );
        });
    }, [connectedWalletAddress, location.pathname, gameId]);

    return moveHistory;
}

export function useGameStartedSubscription(connectedWalletAddress) {
    useEffect(() => {
        window.cc_standardGameContract.deployed().then((instance) => {
            instance.GameStart(
                {
                    filter: { address1: connectedWalletAddress },
                    fromBlock: 0,
                },
                function (err, e) {
                    gameStartedToast(
                        e.returnValues.gameId,
                        e.returnValues.address2
                    );
                }
            );
        });
    }, [connectedWalletAddress]);
}

export function useCheckmateSubscription(connectedWalletAddress) {
    useEffect(() => {
        window.cc_standardGameContract.deployed().then((instance) => {
            instance.Checkmate(
                {
                    filter: { loser: connectedWalletAddress },
                    fromBlock: 0,
                },
                function (err, e) {
                    checkmatedToast(
                        e.returnValues.gameId,
                        e.returnValues.winner
                    );
                }
            );
        });
    }, [connectedWalletAddress]);
}
