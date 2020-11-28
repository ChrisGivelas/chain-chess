import React, { useEffect, useState } from "react";
import Chessboard from "chessboardjsx";
import { getActiveGames } from "../standardGame";
import { useHistory } from "react-router-dom";
import { getAddressBlockie } from "../utils/eth";

function ActiveGames({ connectedWalletAddress, standardGameContract }) {
    const history = useHistory();

    const [activeGames, setActiveGames] = useState(null);

    useEffect(() => {
        if (activeGames === null) {
            getActiveGames(connectedWalletAddress).then((active) => {
                var games = active.gameIds.map((id, i) => ({
                    gameId: id,
                    opponent: active.opponentAddresses[i],
                }));

                setActiveGames(games);
            });
        }
    }, [activeGames, standardGameContract, connectedWalletAddress]);

    const onClick = (gameId) => () => {
        history.push(`/game/${gameId}`);
    };

    return (
        <div>
            {Array.isArray(activeGames) && activeGames.length > 0 ? (
                activeGames.map((activeGame) => (
                    <div
                        key={`${activeGame.gameId}_${activeGame.opponent}`}
                        className="active-game"
                    >
                        <div
                            onClick={onClick(activeGame.gameId)}
                            className="blockie-holder"
                        >
                            <p className="short-address">
                                {activeGame.opponent}
                            </p>
                            {getAddressBlockie(activeGame.opponent)}
                        </div>
                        <div className="chessboard-holder blurred">
                            <Chessboard
                                className="blurred-chessboard"
                                position="start"
                                calcWidth={({ screenWidth }) => screenWidth / 4}
                            />
                        </div>
                    </div>
                ))
            ) : (
                <h1>No Active Games.</h1>
            )}
        </div>
    );
}

export default ActiveGames;
