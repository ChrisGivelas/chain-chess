import "./App.css";
import { useContract } from "./hooks";
import { Button, Loader } from "rimble-ui";
import { useEffect, useState } from "react";
import Chessboard from "chessboardjsx";

function Landing({ connectWallet }) {
    return (
        <header className="App-header">
            <h1>
                Welcome to ChainChess,
                <br />a decentalized chess paridise!🍹
            </h1>

            <h2>New modes coming soon!</h2>
            <Button onClick={connectWallet}>
                Connect Wallet to start playing!
            </Button>
        </header>
    );
}

function Game() {
    return <Chessboard />;
}

function ActiveGames({ connectedWalletAddress, StandardGameContract }) {
    const [activeGames, setActiveGames] = useState(null);

    useEffect(() => {
        if (activeGames === null) {
            StandardGameContract.deployed().then(async (instance) => {
                var games = await instance.getActiveGames({
                    from: connectedWalletAddress,
                });
                games.forEach(console.log);
                setActiveGames(games);
            });
        }
    }, [activeGames]);

    return (
        <div style={{ width: 500, height: 500 }}>
            {Array.isArray(activeGames) &&
                activeGames.map((activeGame) => (
                    <div style={{ filter: "blur(50%)" }}>
                        <Chessboard position="start" />
                    </div>
                ))}
        </div>
    );
}

function GameSearch({ connectedWalletAddress, StandardGameContract }) {
    const [declaredSearching, setDeclaredSearching] = useState(null);
    const [otherUsersSearching, setOtherUsersSearching] = useState(null);

    function declareSearchingForGame() {
        if (declaredSearching !== true) {
            StandardGameContract.deployed()
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
            StandardGameContract.deployed()
                .then((instance) => {
                    return instance.getUsersSearchingForGame(6, {
                        from: connectedWalletAddress,
                    });
                })
                .then((otherUsersSearching) => {
                    setOtherUsersSearching(otherUsersSearching);
                });
        }

        if (declaredSearching === null) {
            StandardGameContract.deployed()
                .then((instance) => {
                    return instance.searchingForNewGameIndex(
                        connectedWalletAddress,
                        {
                            from: connectedWalletAddress,
                        }
                    );
                })
                .then((isSearching) => {
                    setDeclaredSearching(isSearching);
                });
        }
    }, [otherUsersSearching, declaredSearching]);

    return (
        <div>
            {declaredSearching ? (
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
    const StandardGameContract = useContract("StandardGame");

    function connectWallet() {
        window.ethereum
            .enable()
            .then((address) => setConnectedWalletAddress(address));
    }

    return (
        <div className="App">
            {connectedWalletAddress === null ? (
                <Landing connectWallet={connectWallet} />
            ) : (
                <GameSearch
                    userAddress={connectedWalletAddress}
                    StandardGameContract={StandardGameContract}
                />
            )}
        </div>
    );
}

export default App;
