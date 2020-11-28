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
    }, [connectedWalletAddress, isSearching]);

    return (
        playerProfile && (
            <div className="profile">
                <h1>Address: {profileAddress}</h1>
                <h2>Wins: {playerProfile.wins}</h2>
                <h2>Losses: {playerProfile.losses}</h2>
                {connectedWalletAddress === profileAddress &&
                    (isSearching ? (
                        <h3>
                            You have declared your intent to wage war. A
                            challenger shall arrive soon...
                        </h3>
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
