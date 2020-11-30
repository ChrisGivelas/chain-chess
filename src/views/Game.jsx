import React from "react";
import Chessboard from "chessboardjsx";
import { getGameByGameId, movePiece } from "../standardGame";
import { getGameChessboard } from "../utils/chess";
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

        this.state = {
            gameInfo: null,
            chessboard: {
                chess: new Chess(),
                positions: {},
            },
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

        if (!window.MovePieceSubscriptionForGame) {
            window.MovePieceSubscription = await Subscribe_PieceMove(
                { player: connectedWalletAddress },
                (err, e) => {
                    getGameByGameId(connectedWalletAddress, gameId).then(
                        (game) => {
                            that.setState({
                                gameInfo: game,
                                chessboard: getGameChessboard(game.moveHistory),
                            });
                        }
                    );
                }
            );
        }

        getGameByGameId(connectedWalletAddress, gameId).then((game) => {
            that.setState({
                gameInfo: game,
                chessboard: getGameChessboard(game.moveHistory),
            });
        });
    }

    onDrop = ({ sourceSquare, targetSquare }) => {
        const that = this;

        const { chessboard } = this.state;
        const {
            connectedWalletAddress,
            match: {
                params: { gameId },
            },
        } = this.props;

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
                .then(() => getGameByGameId(connectedWalletAddress, gameId))
                .then((game) => {
                    console.log(game);
                    that.setState({
                        gameInfo: game,
                        chessboard: getGameChessboard(game.moveHistory),
                    });
                })
                .catch((err) => {
                    console.log("Move failed:", err);
                });
        }
    };

    render() {
        const { gameInfo, chessboard } = this.state;
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
                        position={chessboard.positions}
                        onDrop={this.onDrop}
                    />
                </div>
            </React.Fragment>
        );
    }
}

export default withRouter(Game);
