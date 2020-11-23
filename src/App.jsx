import React from "react";
import "./App.css";
import { updateWeb3AndReturnWeb3Provider, checksumAddr } from "./utils/eth";
import { getStandardGameContract } from "./standardGame";
import { BrowserRouter, Route, Switch, Redirect } from "react-router-dom";
import { PrivateRoute } from "./utils/route";
import Landing from "./views/Landing";
import ActiveGames from "./views/ActiveGames";
import GameSearch from "./views/GameSearch";
import Profile from "./views/Profile";
import Game from "./views/Game";

class App extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            connectedWalletAddress: null,
            usersSearching: null,
            isLoading: false,
        };
    }

    setupWeb3AndSetContract = () => {
        console.log("setup web3 & contract");
        var web3Provider = updateWeb3AndReturnWeb3Provider();
        window.cc_standardGameContract = getStandardGameContract(web3Provider);
    };

    handleSetUsersSearching = (newVal) =>
        this.setState({ usersSearching: newVal });

    refreshEthUtilsIfNecessary = () => {
        const needToConnectWallet = window.ethereum.selectedAddress === null;
        const contractLoaded = window.cc_standardGameContract !== undefined;

        if (!needToConnectWallet) {
            if (!contractLoaded) {
                this.setupWeb3AndSetContract();
            }
            if (
                this.state.connectedWalletAddress !==
                checksumAddr(window.ethereum.selectedAddress)
            ) {
                this.setState({
                    connectedWalletAddress: checksumAddr(
                        window.ethereum.selectedAddress
                    ),
                });
            }
        }
    };

    componentDidMount() {
        const that = this;

        that.refreshEthUtilsIfNecessary();

        window.ethereum.on("accountsChanged", async function () {
            console.log("accountsChanged");

            if (
                that.state.connectedWalletAddress !==
                checksumAddr(window.ethereum.selectedAddress)
            ) {
                that.setState({
                    connectedWalletAddress: checksumAddr(
                        window.ethereum.selectedAddress
                    ),
                    declaredSearching: null,
                    usersSearching: null,
                });
            }
        });
    }

    componentDidUpdate() {
        this.refreshEthUtilsIfNecessary();
    }

    connectWallet = () => {
        console.log("connect wallet");
        this.setState({ isLoading: true });

        window.ethereum
            .enable()
            .then(() => {
                this.setupWeb3AndSetContract();
                if (
                    this.state.connectedWalletAddress !==
                    checksumAddr(window.ethereum.selectedAddress)
                ) {
                    this.setState({
                        connectedWalletAddress: checksumAddr(
                            window.ethereum.selectedAddress
                        ),
                    });
                }
            })
            .finally(() => {
                this.setState({ isLoading: false });
            });
    };

    render() {
        const needToConnectWallet = window.ethereum.selectedAddress === null;
        const contractLoaded = window.cc_standardGameContract !== undefined;

        const viewProps = {
            handleSetUsersSearching: this.handleSetUsersSearching,
            ...this.state,
        };

        const isAuthenticated = !needToConnectWallet && contractLoaded;

        const privateRouteProps = {
            redirectPath: "/",
            isAuthenticated,
        };

        // console.log("viewProps: ", viewProps);
        // console.log("privateRouteProps: ", privateRouteProps);

        return (
            <div className="App">
                <BrowserRouter>
                    <Switch>
                        <Route
                            exact
                            path="/"
                            render={({ location }) =>
                                !isAuthenticated ? (
                                    <Landing
                                        connectWallet={this.connectWallet}
                                    />
                                ) : (
                                    <Redirect
                                        to={{
                                            pathname: "/search",
                                            state: { from: location },
                                        }}
                                    />
                                )
                            }
                        ></Route>
                        <PrivateRoute path="/search" {...privateRouteProps}>
                            <GameSearch {...viewProps} />
                        </PrivateRoute>
                        <PrivateRoute
                            path="/activeGames"
                            {...privateRouteProps}
                        >
                            <ActiveGames {...viewProps} />
                        </PrivateRoute>
                        <PrivateRoute path="/profile" {...privateRouteProps}>
                            <Profile {...viewProps} />
                        </PrivateRoute>
                        <PrivateRoute
                            path="/game/:gameId"
                            {...privateRouteProps}
                        >
                            <Game
                                connectedWalletAddress={
                                    this.state.connectedWalletAddress
                                }
                            />
                        </PrivateRoute>
                    </Switch>
                </BrowserRouter>
            </div>
        );
    }
}

export default App;
