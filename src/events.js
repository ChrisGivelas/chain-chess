export function Subscribe_PieceMove(filter, callback) {
    console.log("Subscribe_PieceMove");
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.PieceMove(
            {
                filter,
                fromBlock: "pending",
            },
            callback
        );
    });
}

export function Subscribe_GameStart(filter, callback) {
    console.log("Subscribe_GameStart");
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.GameStart(
            {
                filter,
                fromBlock: "pending",
            },
            callback
        );
    });
}

export function Subscribe_Checkmate(filter, callback) {
    console.log("Subscribe_Checkmate");
    return window.cc_standardGameContract.deployed().then(async (instance) => {
        return await instance.Checkmate(
            {
                filter,
                fromBlock: "pending",
            },
            callback
        );
    });
}
