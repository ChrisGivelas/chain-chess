import React, { useCallback, useEffect, useState } from "react";
import { Button, Flash } from "rimble-ui";
import Chessboard from "chessboardjsx";
import { checksumAddr, getAddressBlockie } from "../utils/eth";
import AcceptGameModal from "../components/acceptGameModal";
import { getUsersSearchingForGame } from "../standardGame";

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
        <div className="gamesearch">
            {Array.isArray(otherUsersSearching) &&
            otherUsersSearching.length > 0 ? (
                otherUsersSearching.map((addr, i) => {
                    const AcceptGameModalTrigger = ({ onClick }) => (
                        <div onClick={onClick} className="blockie-holder">
                            <p className="short-address">{addr}</p>
                            {getAddressBlockie(addr)}
                        </div>
                    );
                    return (
                        <div
                            key={`open_game_${addr}`}
                            className="gamesearch-grid"
                        >
                            <div
                                key={`${addr}_${i}`}
                                className="searching-opponent"
                            >
                                <AcceptGameModal
                                    OpenModalComponent={AcceptGameModalTrigger}
                                    connectedWalletAddress={
                                        connectedWalletAddress
                                    }
                                    opponentAddress={addr}
                                />
                                <div className="chessboard-holder blurred">
                                    <Chessboard
                                        className="blurred-chessboard"
                                        position="start"
                                        calcWidth={({ screenWidth }) =>
                                            screenWidth / 4
                                        }
                                    />
                                </div>
                            </div>
                        </div>
                    );
                })
            ) : (
                <h1>No other users are searching right now.</h1>
            )}
        </div>
    );
}

export default GameSearch;
