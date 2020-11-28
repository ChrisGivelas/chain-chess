import React, { useCallback, useEffect, useState } from "react";
import Chessboard from "chessboardjsx";
// import { Chess } from "chess.js";
import { useParams, useLocation } from "react-router-dom";
import { getGameByGameId, movePiece } from "../standardGame";
import { getGameChessboard } from "../utils/chess";
import { Card } from "rimble-ui";
import { getAddressBlockie } from "../utils/eth";
import { useMovePieceSubscription } from "../hooks/events";
import Chess from "chess.js";

import BlackKing from "../assets/bk";
import WhiteKing from "../assets/wk";

function Game({ connectedWalletAddress }) {
    const { gameId } = useParams();
    const { state } = useLocation();
    const [gameInfo, setGameInfo] = useState(null);
    const [chessboard, setChessboard] = useState({
        chess: new Chess(),
        positions: {},
    });
    const moveHistory = useMovePieceSubscription(gameId);
    const updateChessboard = useCallback(
        (moveHistory) => {
            setChessboard(getGameChessboard(moveHistory, chessboard.chess));
        },
        [chessboard.chess]
    );

    const onDrop = ({ sourceSquare, targetSquare }) => {
        let move = chessboard.chess.move({
            from: sourceSquare,
            to: targetSquare,
            promotion: "q", // always promote to a queen for example simplicity
        });

        // illegal move
        if (move === null) return;
        else {
            movePiece(
                connectedWalletAddress,
                gameId,
                sourceSquare,
                targetSquare
            )
                .then((success) => {
                    console.log("Move success:", success);
                })
                .catch((err) => {
                    console.log("Move failed:", err);
                });
        }
    };

    useEffect(() => {
        if (gameInfo === null) {
            if (state && state.gameInfo) {
                updateChessboard(state.gameInfo.moveHistory);
                setGameInfo(state.gameInfo);
            } else {
                getGameByGameId(connectedWalletAddress, gameId).then((game) => {
                    setGameInfo(game);
                    updateChessboard(game.moveHistory);
                });
            }
        }
    }, [
        gameId,
        state,
        gameInfo,
        setGameInfo,
        connectedWalletAddress,
        updateChessboard,
    ]);

    useEffect(() => {
        if (moveHistory !== null) {
            updateChessboard(moveHistory);
        }
    }, [moveHistory, updateChessboard]);

    return (
        <React.Fragment>
            {gameInfo && (
                <div className="game-players">
                    <div className="player-card-holder">
                        <Card className="blah" width="auto" maxWidth="420px">
                            {gameInfo.black.address ===
                                connectedWalletAddress && (
                                <h3
                                    style={{ color: "black", marginBottom: 10 }}
                                >
                                    You
                                </h3>
                            )}
                            {getAddressBlockie(gameInfo.black.address)}
                            <p
                                className="short-address"
                                style={{ marginLeft: 15 }}
                            >
                                {gameInfo.black.address}
                            </p>
                            <BlackKing />
                        </Card>
                    </div>
                    <div className="player-card-holder">
                        <Card width="auto" maxWidth="420px">
                            {gameInfo.white.address ===
                                connectedWalletAddress && (
                                <h3
                                    style={{ color: "black", marginBottom: 10 }}
                                >
                                    You
                                </h3>
                            )}
                            {getAddressBlockie(gameInfo.white.address)}
                            <p
                                className="short-address"
                                style={{ marginLeft: 15 }}
                            >
                                {gameInfo.white.address}
                            </p>
                            <WhiteKing />
                        </Card>
                    </div>
                </div>
            )}
            <div className="game">
                <Chessboard position={chessboard.positions} onDrop={onDrop} />
            </div>
        </React.Fragment>
    );
}

export default Game;
