import React from "react";
import { Route, Redirect, withRouter } from "react-router-dom";
import {
    Subscribe_PieceMove,
    Subscribe_GameStart,
    Subscribe_Checkmate,
} from "../hooks/events";
import ActiveGames from "../views/ActiveGames";
import GameSearch from "../views/GameSearch";
import Profile from "../views/Profile";
import Game from "../views/Game";
import { pieceMoveToast, gameStartToast, checkmateToast } from "../utils/toast";

export const PrivateRoutes = withRouter(
    class extends React.Component {
        constructor(props) {
            super(props);

            this.MovePieceSubscription = null;
            this.GameStartSubscription = null;
            this.CheckmateSubscription = null;
        }

        async componentDidMount() {
            const { connectedWalletAddress } = this.props;

            this.MovePieceSubscription = await Subscribe_PieceMove(
                { player: connectedWalletAddress },
                (err, e) =>
                    pieceMoveToast(
                        e.returnValues.gameId,
                        e.returnValues.playerMakingMove
                    )
            );

            this.GameStartSubscription = await Subscribe_GameStart(
                { address1: connectedWalletAddress },
                (err, e) =>
                    gameStartToast(
                        e.returnValues.gameId,
                        e.returnValues.address2
                    )
            );

            this.CheckmateSubscription = await Subscribe_Checkmate(
                { loser: connectedWalletAddress },
                (err, e) =>
                    checkmateToast(e.returnValues.gameId, e.returnValues.winner)
            );
        }

        async componentWillUnmount() {
            this.MovePieceSubscription.unsubscribe();
            this.GameStartSubscription.unsubscribe();
            this.CheckmateSubscription.unsubscribe();
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
