import React, { useEffect, useState } from "react";
import { checksumAddr } from "../utils/eth";
import AcceptGameModal from "../components/acceptGameModal";
import { getUsersSearchingForGame } from "../standardGame";
import OpponentChessboard from "../components/opponentChessboard";

function GameSearch({ connectedWalletAddress }) {
    const [usersSearching, setUsersSearching] = useState(null);

    useEffect(() => {
        if (usersSearching === null) {
            getUsersSearchingForGame().then((users) => {
                setUsersSearching(users.map(checksumAddr));
            });
        }
    }, [connectedWalletAddress, usersSearching]);

    const otherUsersSearching = Array.isArray(usersSearching)
        ? usersSearching.filter((addr) => addr !== connectedWalletAddress)
        : [];

    return (
        <React.Fragment>
            {Array.isArray(otherUsersSearching) &&
            otherUsersSearching.length > 0 ? (
                <div className="gamesearch">
                    {otherUsersSearching.map((addr, i) => {
                        return (
                            <div
                                key={`${addr}_${i}`}
                                className="searching-opponent"
                            >
                                <AcceptGameModal
                                    OpenModalComponent={({ onClick }) => (
                                        <OpponentChessboard
                                            onClick={onClick}
                                            opponentAddress={addr}
                                        />
                                    )}
                                    connectedWalletAddress={
                                        connectedWalletAddress
                                    }
                                    opponentAddress={addr}
                                />
                            </div>
                        );
                    })}
                </div>
            ) : (
                <h1>No other users are searching right now.</h1>
            )}
        </React.Fragment>
    );
}

export default GameSearch;
