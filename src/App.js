import React from "react";
import "./App.css";
import {
    getStandardGameContract,
    updateWeb3AndReturnWeb3Provider,
} from "./utils";
import { Button } from "rimble-ui";
import { useEffect, useState } from "react";
// import Chessboard from "chessboardjsx";

function Landing({ connectWallet }) {
    return (
        <React.Fragment>
            <h1>
                ♘ Welcome to ChainChess, a decentalized chess battleground! ♔
            </h1>

            <Button onClick={connectWallet}>
                Connect metamask wallet to start playing!
            </Button>
        </React.Fragment>
    );
}

// function Game() {
//     return <Chessboard />;
// }

// function ActiveGames({ connectedWalletAddress, standardGameContract }) {
//     const [activeGames, setActiveGames] = useState(null);

//     useEffect(() => {
//         if (activeGames === null) {
//             standardGameContract.deployed().then(async (instance) => {
//                 var games = await instance.getActiveGames({
//                     from: connectedWalletAddress,
//                 });
//                 games.forEach(console.log);
//                 setActiveGames(games);
//             });
//         }
//     }, [activeGames, standardGameContract, connectedWalletAddress]);

//     return (
//         <div>
//             {Array.isArray(activeGames) &&
//                 activeGames.map((activeGame) => (
//                     <div style={{ filter: "blur(50%)" }}>
//                         <Chessboard position="start" />
//                     </div>
//                 ))}
//         </div>
//     );
// }

function GameSearch({ connectedWalletAddress, standardGameContract }) {
    const [declaredSearching, setDeclaredSearching] = useState(null);
    const [otherUsersSearching, setOtherUsersSearching] = useState(null);

    console.log("=================================================");
    console.log("connectedWalletAddress: ", connectedWalletAddress);
    console.log("standardGameContract: ", standardGameContract);
    console.log("declaredSearching: ", declaredSearching);
    console.log("otherUsersSearching: ", otherUsersSearching);
    console.log("=================================================");

    function declareSearchingForGame() {
        if (declaredSearching !== true) {
            standardGameContract
                .deployed()
                .then((instance) => {
                    return instance.declareSearchingForGame({
                        from: connectedWalletAddress,
                    });
                })
                .then((isSearching) => {
                    setDeclaredSearching(isSearching);
                });
        }
    }

    useEffect(() => {
        if (otherUsersSearching === null) {
            standardGameContract
                .deployed()
                .then((instance) => {
                    return instance.getUsersSearchingForGame(6);
                })
                .then((otherUsersSearching) => {
                    setOtherUsersSearching(otherUsersSearching);
                });
        }
    }, [otherUsersSearching, standardGameContract]);

    useEffect(() => {
        if (declaredSearching === null) {
            standardGameContract.deployed().then((instance) => {
                return instance
                    .searchingForNewGameIndex(connectedWalletAddress)
                    .then((isSearching) => {
                        if (window.web3.utils.isBN(isSearching)) {
                            setDeclaredSearching(isSearching.toNumber() === 1);
                        } else {
                            setDeclaredSearching(false);
                        }
                    });
            });
        }
    }, [declaredSearching, standardGameContract, connectedWalletAddress]);

    return (
        <div>
            {declaredSearching && declaredSearching === true ? (
                <h2>
                    You have declared your intent to wage war. A challenger
                    shall arrive soon...
                </h2>
            ) : (
                <Button onClick={declareSearchingForGame}>
                    Declare your need for battle!
                </Button>
            )}
        </div>
    );
}

function App() {
    const [connectedWalletAddress, setConnectedWalletAddress] = useState(null);

    const needToConnectWallet = window.ethereum.selectedAddress === null;
    const contractLoaded = window.cc_standardGameContract !== undefined;

    function setupWeb3AndSetContract() {
        console.log("setup web3 & contract");
        var web3Provider = updateWeb3AndReturnWeb3Provider();
        window.cc_standardGameContract = getStandardGameContract(web3Provider);
    }

    window.ethereum.on("accountsChanged", async function () {
        console.log("accountsChanged");

        if (connectedWalletAddress !== window.ethereum.selectedAddress) {
            setConnectedWalletAddress(window.ethereum.selectedAddress);
        }
    });

    function connectWallet() {
        if (needToConnectWallet) {
            console.log("connect wallet");

            window.ethereum.enable().then(() => {
                setupWeb3AndSetContract();
                if (connectedWalletAddress !== window.ethereum.selectedAddress)
                    setConnectedWalletAddress(window.ethereum.selectedAddress);
            });
        }
    }

    useEffect(() => {
        if (!needToConnectWallet) {
            if (!contractLoaded) {
                setupWeb3AndSetContract();
            }
            if (connectedWalletAddress !== window.ethereum.selectedAddress) {
                setConnectedWalletAddress(window.ethereum.selectedAddress);
            }
        }
    }, [
        connectedWalletAddress,
        setConnectedWalletAddress,
        contractLoaded,
        needToConnectWallet,
    ]);

    return (
        <div className="App">
            <header className="App-header">
                {connectedWalletAddress !== null &&
                window.cc_standardGameContract !== undefined ? (
                    <GameSearch
                        connectedWalletAddress={window.ethereum.selectedAddress}
                        standardGameContract={window.cc_standardGameContract}
                    />
                ) : (
                    <Landing connectWallet={connectWallet} />
                )}
            </header>
        </div>
    );
}

export default App;
