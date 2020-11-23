import React from "react";
import { Route, Redirect } from "react-router-dom";

export function PrivateRoute({
    children,
    isAuthenticated,
    redirectPath,
    ...rest
}) {
    return (
        <Route
            {...rest}
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
