import React from "react";
import { Route, Redirect, withRouter } from "react-router-dom";
import {
    Subscribe_PieceMove,
    Subscribe_GameStart,
    Subscribe_Checkmate,
} from "../events";
import ActiveGames from "../views/ActiveGames";
import GameSearch from "../views/GameSearch";
import Profile from "../views/Profile";
import Game from "../views/Game";
import { pieceMoveToast, gameStartToast, checkmateToast } from "../utils/toast";
import { checksumAddr } from "../utils/eth";

export const PrivateRoutes = withRouter(
    class extends React.Component {
        async componentDidMount() {
            const { connectedWalletAddress } = this.props;

            window.MovePieceSubscription = await Subscribe_PieceMove(
                { otherPlayer: connectedWalletAddress },
                (err, e) => {
                    console.log(e);
                    if (
                        checksumAddr(e.returnValues.playerMakingMove) !==
                        connectedWalletAddress
                    ) {
                        pieceMoveToast(
                            e.returnValues.gameId,
                            checksumAddr(e.returnValues.playerMakingMove)
                        );
                    }
                }
            );
            window.GameStartSubscription = await Subscribe_GameStart(
                { address2: connectedWalletAddress },
                (err, e) =>
                    gameStartToast(
                        e.returnValues.gameId,
                        checksumAddr(e.returnValues.address2)
                    )
            );
            window.CheckmateSubscription = await Subscribe_Checkmate(
                { loser: connectedWalletAddress },
                (err, e) =>
                    checkmateToast(
                        e.returnValues.gameId,
                        checksumAddr(e.returnValues.winner)
                    )
            );
        }

        async componentWillUnmount() {
            if (window.MovePieceSubscription)
                await window.MovePieceSubscription.unsubscribe();
            if (window.GameStartSubscription)
                await window.GameStartSubscription.unsubscribe();
            if (window.CheckmateSubscription)
                await window.CheckmateSubscription.unsubscribe();
        }

        render() {
            const { connectedWalletAddress, privateRouteProps } = this.props;
            return (
                <React.Fragment>
                    <PrivateRoute path="/search" {...privateRouteProps}>
                        <GameSearch
                            connectedWalletAddress={connectedWalletAddress}
                        />
                    </PrivateRoute>
                    <PrivateRoute path="/activeGames" {...privateRouteProps}>
                        <ActiveGames
                            connectedWalletAddress={connectedWalletAddress}
                        />
                    </PrivateRoute>
                    <PrivateRoute
                        path="/profile/:profileAddress?"
                        {...privateRouteProps}
                    >
                        <Profile
                            connectedWalletAddress={connectedWalletAddress}
                        />
                    </PrivateRoute>
                    <PrivateRoute path="/game/:gameId?" {...privateRouteProps}>
                        <Game connectedWalletAddress={connectedWalletAddress} />
                    </PrivateRoute>
                </React.Fragment>
            );
        }
    }
);

export function PrivateRoute({
    path,
    isAuthenticated,
    redirectPath,
    children,
    ...rest
}) {
    return (
        <Route
            {...rest}
            path={path}
            render={({ location }) =>
                isAuthenticated ? (
                    children
                ) : (
                    <Redirect
                        to={{
                            pathname: redirectPath,
                            state: { from: location },
                        }}
                    />
                )
            }
        />
    );
}
