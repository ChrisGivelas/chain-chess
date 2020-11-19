pragma solidity ^0.6.0;

contract ChessGameBase {
    PieceType[8][8] default2dPieceLayout = [
        [PieceType.Rook,PieceType.Knight,PieceType.Bishop,PieceType.Queen,PieceType.King,PieceType.Bishop,PieceType.Knight,PieceType.Rook],
        [PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn],
        [PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None],
        [PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None],
        [PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None],
        [PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None,PieceType.None],
        [PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn,PieceType.Pawn],
        [PieceType.Rook,PieceType.Knight,PieceType.Bishop,PieceType.Queen,PieceType.King,PieceType.Bishop,PieceType.Knight,PieceType.Rook]
    ];

    PlayerSide[8] defaultRankOwnership = [
        PlayerSide.White,
        PlayerSide.White,
        PlayerSide.None,
        PlayerSide.None,
        PlayerSide.None,
        PlayerSide.None,
        PlayerSide.Black,
        PlayerSide.Black
    ];

    enum PieceType { None, Pawn, Knight, Bishop, Rook, Queen, King }
    enum PlayerSide { None, White, Black }

    struct Piece {
        address owner;
        PieceType pieceType;
        PlayerSide side;
        bool hasMadeInitialMove;
    }

    struct Player {
        PlayerSide side;
        uint8 kingRankPos;
        uint8 kingFilePos;
    }

    struct BoardSquare {
        bool isOccupied;
        Piece piece;
    }

    struct Board {
        BoardSquare[8][8] squares;
        mapping(uint8 => address) playerSides;
        mapping(address => Player) players;
        Piece[] capturedPieces;
        PlayerSide inCheck;
    }

    struct Game {
        Board board;
        string moveHistory;
        uint gameId;
        PlayerSide currentTurn;
        bool started;
        bool ended;
        address winner;
    }

    function checkKingState(Game memory game, Player memory player) pure internal returns(bool, bool) {
        uint8 rankPos;
        uint8 filePos;
        
        rankPos = player.kingRankPos;
        filePos = player.kingFilePos;

        if(!positionIsThreatened(rankPos, filePos, game.board, player.side)) {
            return (false, false);
        }

        int8[2][8] memory possibleKingMoves = [
            [-1,-1],
            [-1,int8(0)],
            [-1,int8(1)],
            [int8(0),int8(1)],
            [int8(1),int8(1)],
            [int8(1),0],
            [int8(1),-1],
            [int8(0),-1]
        ];
        //Check for safe spaces for king to move
        for(uint8 i = 0 ; i < possibleKingMoves.length ; i++) {
            int8[2] memory currentMove = possibleKingMoves[i];

            if(int8(rankPos) + currentMove[0] < 0 || int8(rankPos) + currentMove[0] > 7 || int8(filePos) + currentMove[1] < 0 || int8(filePos) + currentMove[1] > 7) {
                continue;
            } else {
                if(!positionIsThreatened(uint8(int8(rankPos) + currentMove[0]), uint8(int8(filePos) + currentMove[1]), game.board, player.side)) return (true, false);
            }
        }

        return (true, true);
    }

    function isValidMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, Piece memory piece, Board memory board) pure internal returns(bool) {
        if(board.squares[newRankPos][newFilePos].isOccupied && board.squares[newRankPos][newFilePos].piece.side == piece.side) return false;

        if(piece.pieceType == PieceType.Pawn) {
            return isValidPawnMove(prevRankPos, prevFilePos, newRankPos, newFilePos, piece, board);
        } else if (piece.pieceType == PieceType.Knight) { 
            return isValidKnightMove(prevRankPos, prevFilePos, newRankPos, newFilePos);
        } else if (piece.pieceType == PieceType.Bishop) {
            return isValidDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (piece.pieceType == PieceType.Rook) {
            return isValidAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (piece.pieceType == PieceType.Queen) {
            return isValidAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true) || isValidDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (piece.pieceType == PieceType.Knight) {
            return isValidKingMove(prevRankPos, prevFilePos, newRankPos, newFilePos, piece, board);
        }
    }

    function isValidDiagonalMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, bool repeating) pure internal returns(bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(rankPosDiff == 0 || filePosDiff == 0) {
            return false;
        }

        if(repeating) {
            return rankPosDiff == filePosDiff;
        } else {
            return rankPosDiff == 1 && filePosDiff == 1;
        }
    }

    function isValidAxialMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, bool repeating) pure internal returns(bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(repeating) {
            return (rankPosDiff == 0 && filePosDiff != 0) || (rankPosDiff != 0 && filePosDiff == 0);
        } else {
            return (rankPosDiff == 0 && filePosDiff == 1) || (rankPosDiff == 1 && filePosDiff == 0);
        }
    }

    function isValidKnightMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos) pure internal returns(bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        return rankPosDiff == 2 && filePosDiff == 1 || rankPosDiff == 1 && filePosDiff == 2;
    }

    function isValidPawnMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, Piece memory piece, Board memory board) pure internal returns(bool) {
        // Make sure pawn is going in correct direction for its side
        if((piece.side == PlayerSide.Black && newRankPos >= prevRankPos) || (newRankPos <= prevRankPos)) {
            return false;
        }

        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(filePosDiff == 0) {
            if(rankPosDiff == 1) return true;
            if(!piece.hasMadeInitialMove && rankPosDiff == 2) return true;
        }

        // Capture move
        if(filePosDiff == 1 && rankPosDiff == 1) {
            return board.squares[newRankPos][newFilePos].isOccupied;
        }

        return false;
    }

    function isValidKingMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, Piece memory piece, Board memory board) pure internal returns(bool) {
        if(isValidAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false) || isValidDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false)) {
            return !positionIsThreatened(newRankPos, newFilePos, board, piece.side);
        }
    }

    function positionIsThreatened(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side) pure internal returns(bool) {
        //Check below ranks, same file
        if(axialIsThreatened(rankPos, filePos, board, side, true, false)) return true;
        //Check above ranks, same file
        if(axialIsThreatened(rankPos, filePos, board, side, true, true)) return true;
        //Check below files, same rank
        if(axialIsThreatened(rankPos, filePos, board, side, false, false)) return true;
        //Check above files, same rank
        if(axialIsThreatened(rankPos, filePos, board, side, false, true)) return true;
        //Check backwardLeft diagonal
        if(diagonalIsThreatened(rankPos, filePos, board, side, false, false, side == PlayerSide.Black ? true : false)) return true;
        //Check backwardRight diagonal
        if(diagonalIsThreatened(rankPos, filePos, board, side, false, true, side == PlayerSide.Black ? true : false)) return true;
        //Check forwardRight diagonal
        if(diagonalIsThreatened(rankPos, filePos, board, side, true, true, side == PlayerSide.White ? true : false)) return true;
        //Check forwardLeft diagonal
        if(diagonalIsThreatened(rankPos, filePos, board, side, true, false, side == PlayerSide.White ? true : false)) return true;
        //Check for threatening knight
        if(knightThreatensPosition(rankPos, filePos, board, side)) return true;
    }

    function axialIsThreatened(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side, bool iteration_dimension, bool iteration_direction) pure internal returns(bool) {
        BoardSquare memory square;
        uint8 iter = iteration_dimension ? rankPos : filePos;
        
        if(iteration_direction ? iter < 7 : iter > 0) {
            iter = iteration_direction ? iter+1 : iter-1;
            while(iteration_direction ? iter <= 7 : iter >= 0) {
                square = board.squares[iteration_dimension ? iter : rankPos][!iteration_dimension ? iter : filePos];
                if(square.isOccupied) {
                    if(square.piece.side == side) {
                        break;
                    } else {
                        if(square.piece.pieceType == PieceType.Queen || square.piece.pieceType == PieceType.Rook) return true;
                    }
                }
                iter = iteration_direction ? iter+1 : iter-1;
            }
        }

        return false;
    }

    function diagonalIsThreatened(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side, bool rank_iteration_direction, bool file_iteration_direction, bool checkForPawn) pure internal returns(bool) {
        if((rank_iteration_direction ? rankPos == 7 : rankPos == 0) || (file_iteration_direction ? filePos == 7 : filePos == 0)) return false;
        BoardSquare memory square;
        uint8 rank_iter = rank_iteration_direction ? rankPos+1 : rankPos-1;
        uint8 file_iter = file_iteration_direction ? filePos+1 : filePos-1;

        if((rank_iteration_direction ? rank_iter < 7 : rank_iter > 0) && (file_iteration_direction ? file_iter < 7 : file_iter > 0)) {
            if(checkForPawn) {
                square = board.squares[rank_iter][file_iter];
                if(square.isOccupied && square.piece.side != side && square.piece.pieceType == PieceType.Pawn) {
                    return true;
                }
            }
            while((rank_iteration_direction ? rank_iter <= 7 : rank_iter >= 0) && (file_iteration_direction ? file_iter <= 7 : file_iter >= 0)) {
                square = board.squares[rank_iter][file_iter];
                if(square.isOccupied) {
                    if(square.piece.side != side && square.piece.pieceType == PieceType.Queen || square.piece.pieceType == PieceType.Bishop) return true;
                    break;
                }
                rank_iter = rank_iteration_direction ? rank_iter+1 : rank_iter-1;
                file_iter = file_iteration_direction ? file_iter+1 : file_iter-1;
            }
        }

        return false;
    }

    function knightThreatensPosition(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side) pure internal returns (bool) {
        int8[2][8] memory possibleKnightMoves = [
            [-2,-1],
            [-2,int8(1)],
            [-1,int8(2)],
            [int8(1),int8(2)],
            [int8(2),int8(1)],
            [int8(2),-1],
            [int8(1),-2],
            [-1,-2]
        ];
        for(uint8 i = 0 ; i < possibleKnightMoves.length ; i++) {
            int8[2] memory currentMove = possibleKnightMoves[i];

            if(int8(rankPos) + currentMove[0] < 0 || int8(rankPos) + currentMove[0] > 7 || int8(filePos) + currentMove[1] < 0 || int8(filePos) + currentMove[1] > 7) {
                continue;
            } else {
                BoardSquare memory squareToCheck = board.squares[uint(int8(rankPos) + currentMove[0])][uint(int8(filePos) + currentMove[1])];
                if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
            }
        }

        return false;
    }

    function getPositionDiff(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos) pure internal returns (uint8 rankPosDiff, uint8 filePosDiff) {
        if(prevRankPos > newRankPos) {
            rankPosDiff = prevRankPos - newRankPos;
        } else if(prevRankPos < newRankPos) {
            rankPosDiff = newRankPos - prevRankPos;
        } else {
            rankPosDiff = 0;
        }

        if(prevFilePos > newFilePos) {
            filePosDiff = prevFilePos - newFilePos;
        } else if(prevFilePos > newFilePos) {
            filePosDiff = newFilePos - prevFilePos;
        } else {
            filePosDiff = 0;
        }
    }

    function clonePiece(Piece memory piece) pure internal returns (Piece memory) {
        return Piece({owner: piece.owner, pieceType: piece.pieceType, side: piece.side, hasMadeInitialMove: piece.hasMadeInitialMove});
    }

    function getMoveHistoryEntry(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, uint8 pieceEnumValue, bool isCapture, bool isGameEnd) internal pure returns(string memory) {
        string[8] memory fileIdMapping = ["a","b","c","d","e","f","g","h"];
        string[8] memory rankIdMapping = ["1","2","3","4","5","6","7","8"];
        string[6] memory pieceIdMapping = ["P", "N", "B", "R", "Q", "K" ];
        return strConcat(
            pieceIdMapping[pieceEnumValue - 1],
            fileIdMapping[prevFilePos],
            rankIdMapping[prevRankPos],
            isCapture ? "x" : "",
            fileIdMapping[newFilePos],
            rankIdMapping[newRankPos],
            !isGameEnd ? "," : "."
        );
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "", "", "");
    }

    // Adapted from https://github.com/provable-things/ethereum-api/blob/9f34daaa550202c44f48cdee7754245074bde65d/oraclizeAPI_0.5.sol#L959
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e, string memory _f, string memory _g) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        bytes memory _bf = bytes(_f);
        bytes memory _bg = bytes(_g);
        string memory abcdefg = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        bytes memory babcdefg = bytes(abcdefg);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcdefg[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcdefg[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcdefg[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcdefg[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcdefg[k++] = _be[i];
        }
        for (i = 0; i < _bf.length; i++) {
            babcdefg[k++] = _bf[i];
        }
        for (i = 0; i < _bg.length; i++) {
            babcdefg[k++] = _bg[i];
        }
        return string(babcdefg);
    }
}