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

export const PrivateRoutes = withRouter(
    class extends React.Component {
        async componentDidMount() {
            const {
                connectedWalletAddress,
                match: {
                    params: { gameId },
                },
            } = this.props;

            if (!window.MovePieceSubscription) {
                window.MovePieceSubscription = await Subscribe_PieceMove(
                    { player: connectedWalletAddress },
                    (err, e) => {
                        pieceMoveToast(
                            e.returnValues.gameId,
                            e.returnValues.playerMakingMove
                        );
                    }
                );
            }

            if (!window.GameStartSubscription) {
                window.GameStartSubscription = await Subscribe_GameStart(
                    { address1: connectedWalletAddress },
                    (err, e) =>
                        gameStartToast(
                            e.returnValues.gameId,
                            e.returnValues.address2
                        )
                );
            }

            if (!window.CheckmateSubscription) {
                window.CheckmateSubscription = await Subscribe_Checkmate(
                    { loser: connectedWalletAddress },
                    (err, e) =>
                        checkmateToast(
                            e.returnValues.gameId,
                            e.returnValues.winner
                        )
                );
            }
        }

        async componentWillUnmount() {
            await window.MovePieceSubscription.unsubscribe();
            window.MovePieceSubscription = undefined;
            await window.GameStartSubscription.unsubscribe();
            window.GameStartSubscription = undefined;
            await window.CheckmateSubscription.unsubscribe();
            window.CheckmateSubscription = undefined;
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
