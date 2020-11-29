import { getAddressBlockie, getShortenedAddress } from "../utils/eth";
import Chessboard from "chessboardjsx";

function OpponentChessboard({ opponentAddress, onClick }) {
    return (
        <div className="opponent-chessboard">
            <div onClick={onClick} className="blockie-holder">
                <span>{getShortenedAddress(opponentAddress)}</span>
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
