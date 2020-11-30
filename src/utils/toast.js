import React from "react";
import { Link } from "react-router-dom";
import { toast } from "react-toastify";
import { getShortenedAddress } from "./eth";
import { Button } from "rimble-ui";

export const viewGameToast = (gameId, msg, showLink) => {
    var Component = ({ closeToast }) => <p>{msg}</p>;

    toast.info(<Component />, {
        className: "toast-container",
        position: "bottom-right",
        autoClose: 10000,
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
