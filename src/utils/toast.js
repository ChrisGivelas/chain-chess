import { Link } from "react-router-dom";
import { toast } from "react-toastify";

export const gameStartedToast = (gameId, opponentAddress) => {
    var Component = ({ closeToast }) => (
        <div className="toast-container">
            <p>{`Game started with ${opponentAddress}!`}</p>
            <Link to={`/game/${gameId}`}>View Game</Link>
        </div>
    );

    toast(<Component />);
};

export const moveTurnToast = (gameId, opponentAddress) => {
    var Component = ({ closeToast }) => (
        <div className="toast-container">
            <p>{`${opponentAddress} made a move!`}</p>
            <Link to={`/game/${gameId}`}>View Game</Link>
        </div>
    );

    toast(<Component />);
};

export const checkmatedToast = (gameId, opponentAddress) => {
    var Component = ({ closeToast }) => (
        <div className="toast-container">
            <p>{`${opponentAddress} checkmated you.`}</p>
            <Link to={`/game/${gameId}`}>View Game</Link>
        </div>
    );

    toast(<Component />);
};
