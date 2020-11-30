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
                <h3 style={{ color: "yellowgreen" }}>{profileAddress}</h3>
                <h3 style={{ color: "green" }}>
                    Wins: <span>{playerProfile.wins}</span>
                </h3>
                <h3 style={{ color: "red" }}>
                    Losses: <span>{playerProfile.losses}</span>
                </h3>
                {connectedWalletAddress === profileAddress &&
                    (isSearching ? (
                        <React.Fragment>
                            <h3>
                                You have declared your intent to wage war. A
                                challenger shall arrive soon...
                            </h3>
                            <h3>
                                (You'll get a notification when someone accepts)
                            </h3>
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
