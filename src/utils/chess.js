import Chess from "chess.js";

export const RANK_MAPPING = ["8", "7", "6", "5", "4", "3", "2", "1"];

// Need to reverse because StandardGame contract starts with white side at lower index ranks
const RANK_MAPPING_REVERSED = ["1", "2", "3", "4", "5", "6", "7", "8"];
export const getRankIndexFromVal = (i) =>
    RANK_MAPPING_REVERSED.findIndex((r) => {
        return r === i;
    });

export const FILE_MAPPING = ["a", "b", "c", "d", "e", "f", "g", "h"];

export const getFileIndexFromVal = (i) =>
    FILE_MAPPING.findIndex((f) => {
        return f === i;
    });

export const getGameChessboard = (moveHistory = "") => {
    var c = new Chess();

    if (moveHistory.length > 0) {
        moveHistory.split(",").forEach((moveEntry) => {
            c.move(moveEntry, { sloppy: true });
        });
    }

    return { chess: c, positions: getPositionObjectFromChessboard(c) };
};

export const getPositionObjectFromChessboard = (chess) => {
    let positionObject = {};

    var board2dArray = chess.board();

    for (var rank_iter = 0; rank_iter < board2dArray.length; rank_iter++) {
        for (
            var file_iter = 0;
            file_iter < board2dArray[rank_iter].length;
            file_iter++
        ) {
            var square = board2dArray[rank_iter][file_iter];
            if (square !== null) {
                positionObject[
                    `${FILE_MAPPING[file_iter]}${RANK_MAPPING[rank_iter]}`
                ] = `${square.color}${square.type.toUpperCase()}`;
            }
        }
    }

    return positionObject;
};
