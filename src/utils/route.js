import React from "react";
import { Route, Redirect } from "react-router-dom";
import {
    useGameStartedSubscription,
    useMovePieceSubscription,
    useCheckmateSubscription,
} from "../hooks/events";

export function PrivateRouteWrapper({ connectedWalletAddress, Component }) {
    useMovePieceSubscription(connectedWalletAddress);
    useGameStartedSubscription(connectedWalletAddress);
    useCheckmateSubscription(connectedWalletAddress);

    return <Component connectedWalletAddress={connectedWalletAddress} />;
}

export function PrivateRoute({
    path,
    isAuthenticated,
    redirectPath,
    connectedWalletAddress,
    Component,
    ...rest
}) {
    return (
        <Route
            {...rest}
            path={path}
            render={({ location }) =>
                isAuthenticated ? (
                    <PrivateRouteWrapper
                        connectedWalletAddress={connectedWalletAddress}
                        Component={Component}
                    />
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
