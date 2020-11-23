import React, { useCallback, useEffect, useState } from "react";
import { Button, Flash } from "rimble-ui";
import Chessboard from "chessboardjsx";
import { checksumAddr, getAddressBlockie } from "../ethUtils";
import AcceptGameModal from "../components/acceptGameModal";

function GameSearch({
    handleSetUsersSearching,
    connectedWalletAddress,
    usersSearching,
}) {
    const [error, setError] = useState(null);

    function declareSearchingForGame() {
        setError(null);

        window.cc_standardGameContract.deployed().then((instance) => {
            instance
                .declareSearchingForGame({
                    from: connectedWalletAddress,
                })
                .then(getUsersSearchingForGame)
                .catch((err) => {
                    console.log("Error: ", err);
                    setError(err);
                });
        });
    }

    const getUsersSearchingForGame = useCallback(() => {
        window.cc_standardGameContract.deployed().then((instance) => {
            instance.getUsersSearchingForGame().then((usersSearching) => {
                handleSetUsersSearching(usersSearching.map(checksumAddr));
            });
        });
    }, [handleSetUsersSearching]);

    useEffect(() => {
        if (usersSearching === null) {
            getUsersSearchingForGame();
        }
    }, [connectedWalletAddress, usersSearching, getUsersSearchingForGame]);

    function connectedWalletIsSearching() {
        if (Array.isArray(usersSearching) && usersSearching.length > 0) {
            return usersSearching.some(
                (addr) => addr === connectedWalletAddress
            );
        }
    }

    // console.log(connectedWalletAddress, usersSearching, declaredSearching);

    const otherUsersSearching = Array.isArray(usersSearching)
        ? usersSearching.filter((addr) => addr !== connectedWalletAddress)
        : [];

    return (
        <div>
            {error !== null && <Flash variant="danger">{error}</Flash>}
            {connectedWalletIsSearching() ? (
                <h3>
                    You have declared your intent to wage war. A challenger
                    shall arrive soon...
                </h3>
            ) : (
                <Button onClick={declareSearchingForGame}>
                    Declare your need for battle!
                </Button>
            )}

            <div className="gamesearch-grid">
                {Array.isArray(otherUsersSearching) &&
                    otherUsersSearching.length > 0 &&
                    otherUsersSearching.map((addr, i) => {
                        const AcceptGameModalTrigger = ({ onClick }) => (
                            <div onClick={onClick} className="blockie-holder">
                                <p className="short-address">{addr}</p>
                                {getAddressBlockie(addr)}
                            </div>
                        );
                        return (
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
                        );
                    })}
            </div>
        </div>
    );
}

export default GameSearch;
