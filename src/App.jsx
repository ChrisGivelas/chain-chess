import React from "react";
import "./App.css";
import { updateWeb3AndReturnWeb3Provider, checksumAddr } from "./utils/eth";
import { getStandardGameContract } from "./standardGame";
import { Route, Switch, withRouter } from "react-router-dom";
import { PrivateRoute } from "./utils/route";
import Landing from "./views/Landing";
import ActiveGames from "./views/ActiveGames";
import GameSearch from "./views/GameSearch";
import Profile from "./views/Profile";
import Game from "./views/Game";
import Nav from "./components/nav";

class App extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            connectedWalletAddress: null,
        };

        this.refreshEthUtilsIfNecessary();
    }

    setupWeb3AndSetContract = () => {
        console.log("setup web3 & contract");
        var web3Provider = updateWeb3AndReturnWeb3Provider();
        window.cc_standardGameContract = getStandardGameContract(web3Provider);
    };

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
            console.log("accounts changed");

            if (window.ethereum.selectedAddress === null) {
                that.setState({
                    connectedWalletAddress: null,
                    declaredSearching: null,
                    usersSearching: null,
                });
            } else if (
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
                const newEthAddress = checksumAddr(
                    window.ethereum.selectedAddress
                );
                if (this.state.connectedWalletAddress !== newEthAddress) {
                    this.setState({
                        connectedWalletAddress: newEthAddress,
                    });
                }
            })
            .finally(() => {
                this.setState({ isLoading: false });

                this.props.history.push(
                    `/profile/${checksumAddr(window.ethereum.selectedAddress)}`
                );
            });
    };

    render() {
        const needToConnectWallet = window.ethereum.selectedAddress === null;
        const contractLoaded = window.cc_standardGameContract !== undefined;

        const dappReady = !needToConnectWallet && contractLoaded;

        const privateRouteProps = {
            redirectPath: "/",
            isAuthenticated: dappReady,
        };

        return (
            <div className="App">
                <Nav
                    connectedWalletAddress={this.state.connectedWalletAddress}
                />
                <div className="main">
                    <Switch>
                        <Route exact path="/">
                            <Landing connectWallet={this.connectWallet} />
                        </Route>
                        <PrivateRoute path="/search" {...privateRouteProps}>
                            <GameSearch {...this.state} />
                        </PrivateRoute>
                        <PrivateRoute
                            path="/activeGames"
                            {...privateRouteProps}
                        >
                            <ActiveGames {...this.state} />
                        </PrivateRoute>
                        <PrivateRoute
                            path="/profile/:profileAddress?"
                            {...privateRouteProps}
                        >
                            <Profile {...this.state} />
                        </PrivateRoute>
                        <PrivateRoute
                            path="/game/:gameId?"
                            {...privateRouteProps}
                        >
                            <Game
                                connectedWalletAddress={
                                    this.state.connectedWalletAddress
                                }
                            />
                        </PrivateRoute>
                    </Switch>
                </div>
            </div>
        );
    }
}

export default withRouter(App);
