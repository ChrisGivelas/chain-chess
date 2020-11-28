import { getAddressBlockie } from "../utils/eth";
import Chessboard from "chessboardjsx";

function OpponentChessboard({ opponentAddress, onClick }) {
    return (
        <div className="opponent-chessboard">
            <div onClick={onClick} className="blockie-holder">
                <p className="short-address">{opponentAddress}</p>
                {getAddressBlockie(opponentAddress)}
            </div>
            <div className="chessboard-holder blurred">
                <Chessboard
                    className="blurred-chessboard"
                    position="start"
                    calcWidth={({ screenWidth }) => screenWidth / 4}
                />
            </div>
        </div>
    );
}

export default OpponentChessboard;
