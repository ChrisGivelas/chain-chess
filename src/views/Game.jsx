import React from "react";
import Chessboard from "chessboardjsx";
import { getGameByGameId, movePiece } from "../standardGame";
import { simulateMoves } from "../utils/chess";
import { Card } from "rimble-ui";
import { getAddressBlockie, getShortenedAddress } from "../utils/eth";
import Chess from "chess.js";
import BlackKing from "../assets/bk";
import WhiteKing from "../assets/wk";
import { withRouter } from "react-router-dom";
import { Subscribe_PieceMove } from "../events";

class Game extends React.Component {
    constructor(props) {
        super(props);

        this.chess = new Chess();

        this.state = {
            gameInfo: null,
        };
    }

    async componentDidMount() {
        var that = this;

        const {
            connectedWalletAddress,
            match: {
                params: { gameId },
            },
        } = this.props;

        window.MovePieceSubscriptionForGame = await Subscribe_PieceMove(
            { otherPlayer: connectedWalletAddress, gameId: gameId },
            (err, e) => {
                that.chess.move(e.returnValues.moveHistoryEntry, {
                    sloppy: true,
                });
                getGameByGameId(connectedWalletAddress, gameId).then((game) => {
                    that.setState({
                        gameInfo: game,
                    });
                });
            }
        );

        getGameByGameId(connectedWalletAddress, gameId).then((game) => {
            simulateMoves(that.chess, game.moveHistory);

            that.setState({
                gameInfo: game,
            });
        });
    }

    async componentWillUnmount() {
        await window.MovePieceSubscriptionForGame.unsubscribe();
        window.MovePieceSubscriptionForGame = undefined;
    }

    onDrop = ({ sourceSquare, targetSquare }) => {
        const that = this;

        const {
            connectedWalletAddress,
            match: {
                params: { gameId },
            },
        } = this.props;

        let move = this.chess.move({
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
                .then((tx) => {
                    const { moveHistoryEntry } = tx.logs[0].args;
                    that.chess.move(moveHistoryEntry, {
                        sloppy: true,
                    });
                    getGameByGameId(connectedWalletAddress, gameId).then(
                        (game) => {
                            that.setState({
                                gameInfo: game,
                            });
                        }
                    );
                })
                .catch((err) => {
                    console.log("Move failed:", err);
                });
        }
    };

    render() {
        console.log(this.state.gameInfo);
        const { gameInfo } = this.state;
        const { connectedWalletAddress } = this.props;
        return (
            <React.Fragment>
                {gameInfo && gameInfo.black && gameInfo.white && (
                    <div className="game-players">
                        <div className="player-card-holder">
                            <Card width="auto" maxWidth="420px">
                                {gameInfo.black.address ===
                                    connectedWalletAddress && (
                                    <h3
                                        style={{
                                            color: "black",
                                            marginBottom: 10,
                                        }}
                                    >
                                        You
                                    </h3>
                                )}
                                {getAddressBlockie(gameInfo.black.address)}
                                {getShortenedAddress(gameInfo.black.address)}
                                <BlackKing />
                            </Card>
                        </div>
                        <div className="player-card-holder">
                            <Card width="auto" maxWidth="420px">
                                {gameInfo.white.address ===
                                    connectedWalletAddress && (
                                    <h3
                                        style={{
                                            color: "black",
                                            marginBottom: 10,
                                        }}
                                    >
                                        You
                                    </h3>
                                )}
                                {getAddressBlockie(gameInfo.white.address)}
                                {getShortenedAddress(gameInfo.white.address)}
                                <WhiteKing />
                            </Card>
                        </div>
                    </div>
                )}
                <div className="game">
                    {gameInfo &&
                        (gameInfo.ended ? (
                            <h3>{`${gameInfo.currentTurn} is the winner!`}</h3>
                        ) : (
                            <h3>{`It is ${gameInfo.currentTurn}'s turn.`}</h3>
                        ))}
                    <Chessboard
                        position={this.chess.fen()}
                        onDrop={this.onDrop}
                    />
                </div>
            </React.Fragment>
        );
    }
}

export default withRouter(Game);
