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

export const simulateMoves = (c, moveHistory = "") => {
    if (moveHistory.length > 0) {
        moveHistory.split(",").forEach((moveEntry) => {
            c.move(moveEntry, { sloppy: true });
        });
    }
};
