import React, { useEffect, useState } from "react";
import Chessboard from "chessboardjsx";
import { Chess } from "chess.js";
import { useParams, useLocation, useHistory } from "react-router-dom";
import { Flash, Button } from "rimble-ui";

function Game({ connectedWalletAddress }) {
    const { gameId } = useParams();
    const {
        state: { game },
    } = useLocation();

    return <div className="game-view"></div>;
}

export default Game;
