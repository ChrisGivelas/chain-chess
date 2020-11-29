import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import {
    getPlayerProfile,
    declareSearchingForGame,
    userIsSearching,
} from "../standardGame";
import { Button } from "rimble-ui";

function Profile({ connectedWalletAddress }) {
    const { profileAddress } = useParams();
    const [playerProfile, setPlayerProfile] = useState(null);
    const [isSearching, setIsSearching] = useState(null);

    const searchForGame = () => {
        declareSearchingForGame(connectedWalletAddress)
            .then(() => userIsSearching(connectedWalletAddress))
            .then(setIsSearching)
            .catch((err) => {
                console.log("Error: ", err);
            });
    };

    useEffect(() => {
        if (profileAddress) {
            if (playerProfile === null) {
                getPlayerProfile(profileAddress).then(setPlayerProfile);
            }
        } else {
            console.log("Error: Profile does not exist!");
        }
    }, [profileAddress, playerProfile]);

    useEffect(() => {
        if (isSearching === null && connectedWalletAddress === profileAddress) {
            userIsSearching(connectedWalletAddress).then(setIsSearching);
        }
    }, [connectedWalletAddress, isSearching, profileAddress]);

    return (
        playerProfile && (
            <div className="profile">
                <h2 style={{ color: "yellowgreen" }}>{profileAddress}</h2>
                <h2 style={{ color: "green" }}>
                    Wins: <span>{playerProfile.wins}</span>
                </h2>
                <h2 style={{ color: "red" }}>
                    Losses: <span>{playerProfile.losses}</span>
                </h2>
                {connectedWalletAddress === profileAddress &&
                    (isSearching ? (
                        <React.Fragment>
                            <h2>
                                You have declared your intent to wage war. A
                                challenger shall arrive soon...
                            </h2>
                            <h4>
                                (You'll get a notification when someone accepts)
                            </h4>
                        </React.Fragment>
                    ) : (
                        <Button onClick={searchForGame}>
                            Declare your need for battle!
                        </Button>
                    ))}
            </div>
        )
    );
}

export default Profile;
