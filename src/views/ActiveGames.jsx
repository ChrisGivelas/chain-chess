import React, { useEffect, useState } from "react";
import Chessboard from "chessboardjsx";

function ActiveGames({ connectedWalletAddress, standardGameContract }) {
    const [activeGames, setActiveGames] = useState(null);

    useEffect(() => {
        if (activeGames === null) {
            standardGameContract.deployed().then(async (instance) => {
                var games = await instance.getActiveGames({
                    from: connectedWalletAddress,
                });
                setActiveGames(games);
            });
        }
    }, [activeGames, standardGameContract, connectedWalletAddress]);

    return (
        <div>
            {Array.isArray(activeGames) &&
                activeGames.map((activeGame) => (
                    <div style={{ filter: "blur(50%)" }}>
                        <Chessboard position="start" />
                    </div>
                ))}
        </div>
    );
}

export default ActiveGames;
