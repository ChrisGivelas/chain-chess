import React from "react";
import { Link } from "react-router-dom";
import { toast } from "react-toastify";
import { getShortenedAddress } from "./eth";
import { Button } from "rimble-ui";

export const viewGameToast = (gameId, msg, showLink) => {
    var Component = ({ closeToast }) => (
        <React.Fragment>
            <p>{msg}</p>
            {showLink && (
                <Button>
                    <Link className="view-game-link" to={`/game/${gameId}`}>
                        Click to View Game
                    </Link>
                </Button>
            )}
        </React.Fragment>
    );

    toast.info(<Component />, {
        className: "toast-container",
        position: "bottom-right",
        autoClose: false,
    });
};

export const gameStartToast = (gameId, opponentAddress, showLink = true) => {
    viewGameToast(
        gameId,
        `Game started with ${getShortenedAddress(opponentAddress)}!`,
        showLink
    );
};

export const pieceMoveToast = (gameId, opponentAddress, showLink = true) => {
    viewGameToast(
        gameId,
        `${getShortenedAddress(opponentAddress)} made a move!`,
        showLink
    );
};

export const checkmateToast = (gameId, opponentAddress, showLink = true) => {
    viewGameToast(
        gameId,
        `${getShortenedAddress(opponentAddress)} checkmated you.`,
        showLink
    );
};
