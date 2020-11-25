import React, { useEffect, useState } from "react";
import Chessboard from "chessboardjsx";
// import { Chess } from "chess.js";
import { useParams, useLocation } from "react-router-dom";
import { getGameByGameId, movePiece } from "../standardGame";
import {
    getGameChessboard,
    getPositionObjectFromChessboard,
} from "../utils/chess";
import {
    getOtherPlayersInfoFromGame,
    getPlayerInfoFromGame,
} from "../utils/game_parsing";
import { Card } from "rimble-ui";
import { getAddressBlockie } from "../utils/eth";

function Game({ connectedWalletAddress }) {
    const { gameId } = useParams();
    const { state } = useLocation();
    const [gameInfo, setGameInfo] = useState(null);
    const [chessboard, setChessboard] = useState(null);
    const [chessboardPositions, setChessboardPositions] = useState({});

    const playerInfo = getPlayerInfoFromGame(gameInfo, connectedWalletAddress);
    const otherPlayerInfo = getOtherPlayersInfoFromGame(
        gameInfo,
        connectedWalletAddress
    );

    const setChessInfo = (game) => {
        console.log(game);
        setGameInfo(game);
        var chess = getGameChessboard(game);
        setChessboard(chess);
        setChessboardPositions(getPositionObjectFromChessboard(chess));
    };

    const onDrop = ({ sourceSquare, targetSquare }) => {
        let move = chessboard.move({
            from: sourceSquare,
            to: targetSquare,
            promotion: "q", // always promote to a queen for example simplicity
        });

        // illegal move
        if (move === null) return;
        else {
            movePiece(
                connectedWalletAddress,
                gameInfo.gameId,
                sourceSquare,
                targetSquare
            )
                .then((success) => {
                    console.log("Successful move:", success);
                })
                .catch((err) => {
                    console.log("Err:", err);
                });
        }
    };

    useEffect(() => {
        if (gameInfo === null) {
            if (state && state.gameInfo) {
                setChessInfo(state.gameInfo);
            } else {
                getGameByGameId(connectedWalletAddress, gameId).then((game) => {
                    setChessInfo(game);
                });
            }
        }
    }, [gameId, state, gameInfo, setGameInfo, connectedWalletAddress]);

    return (
        <div className="game-view">
            {playerInfo !== undefined && otherPlayerInfo !== undefined && (
                <div className="game-players">
                    <div className="player-card-holder">
                        <Card width="auto" maxWidth="420px">
                            {getAddressBlockie(otherPlayerInfo.address)}
                            <p
                                className="short-address"
                                style={{ marginLeft: 15 }}
                            >
                                {otherPlayerInfo.address}
                            </p>
                        </Card>
                    </div>
                    <div className="player-card-holder">
                        <Card width="auto" maxWidth="420px">
                            {getAddressBlockie(playerInfo.address)}
                            <p
                                className="short-address"
                                style={{ marginLeft: 15 }}
                            >
                                {playerInfo.address}
                            </p>
                        </Card>
                    </div>
                </div>
            )}
            <div className="game">
                <Chessboard position={chessboardPositions} onDrop={onDrop} />
            </div>
        </div>
    );
}

export default Game;
