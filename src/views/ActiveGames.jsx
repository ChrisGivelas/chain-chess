import React, { useEffect, useState } from "react";
import { getActiveGames } from "../standardGame";
import { useHistory } from "react-router-dom";
import OpponentChessboard from "../components/opponentChessboard";

function ActiveGames({ connectedWalletAddress, standardGameContract }) {
    const history = useHistory();

    const [activeGames, setActiveGames] = useState(null);

    useEffect(() => {
        if (activeGames === null) {
            getActiveGames(connectedWalletAddress).then((active) => {
                var games = active.gameIds.map((id, i) => ({
                    gameId: id,
                    opponentAddress: active.opponentAddresses[i],
                }));

                setActiveGames(games);
            });
        }
    }, [activeGames, standardGameContract, connectedWalletAddress]);

    const onClick = (gameId) => () => {
        history.push(`/game/${gameId}`);
    };

    return (
        <React.Fragment>
            {Array.isArray(activeGames) && activeGames.length > 0 ? (
                <div className="active-games">
                    {activeGames.map((activeGame, i) => (
                        <div
                            key={`${activeGames.gameId}_${i}`}
                            className="active-game"
                        >
                            <OpponentChessboard
                                key={`activegame_${activeGame.gameId}`}
                                onClick={onClick(activeGame.gameId)}
                                {...activeGame}
                            />
                        </div>
                    ))}
                </div>
            ) : (
                <h1>No Active Games.</h1>
            )}
        </React.Fragment>
    );
}

export default ActiveGames;
