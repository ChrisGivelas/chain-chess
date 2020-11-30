pragma solidity >=0.6.0 <0.8.0;

/// @title Library containing fundamental chess validation logic and structs for different concepts of the game
/// @author Christopher Givelas
library Chess {
    uint constant MAX_RANK = 7;
    uint constant MAX_FILE = 7;

    enum PieceType { None, Pawn, Knight, Bishop, Rook, Queen, King }
    enum PlayerSide { None, White, Black }

    struct Piece {
        PieceType pieceType;
        PlayerSide side;
        bool hasMadeInitialMove;
    }

    struct Player {
        PlayerSide side;
        uint kingRank;
        uint kingFile;
    }

    struct BoardSquare {
        bool isOccupied;
        Piece piece;
    }

    struct Board {
        BoardSquare[8][8] squares;
        mapping(uint => address) playerSides;
        mapping(address => Player) players;
        Piece[] capturedPieces;        
    }

    struct Game {
        uint gameId;
        Board board;
        string moveHistory;
        PlayerSide currentTurn;
        PlayerSide inCheck;
        bool started;
        bool ended;
        address winner;
        uint moveCount;
    }
    
    /// @notice Main function called for validating a piece move. Calls appropriate method depending on piece type.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param piece the piece that is being moved
    /// @param board the current chessboard state
    function validateMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Piece memory piece, Board memory board) internal pure {
        require(!(board.squares[newRank][newFile].isOccupied && board.squares[newRank][newFile].piece.side == piece.side), "New square has one of player's own pieces");

        if(piece.pieceType == PieceType.Pawn) {
            validatePawnMove(prevRank, prevFile, newRank, newFile, piece, board);
        } else if (piece.pieceType == PieceType.Knight) { 
            validateKnightMove(prevRank, prevFile, newRank, newFile);  
        }  else if (piece.pieceType == PieceType.Knight) {
            validateKingMove(prevRank, prevFile, newRank, newFile, piece, board);
        } else if (piece.pieceType == PieceType.Bishop) {
            validateDiagonalMove(prevRank, prevFile, newRank, newFile, board, true);
        } else if (piece.pieceType == PieceType.Rook) {
            validateAxialMove(prevRank, prevFile, newRank, newFile, board, true);
        } else if (piece.pieceType == PieceType.Queen) {
            validateDiagonalOrAxialMove(prevRank, prevFile, newRank, newFile, board, true);
        }
    }

    /// @notice Validate a pawn move.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param piece the piece that is being moved
    /// @param board the current chessboard state
    function validatePawnMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Piece memory piece, Board memory board) pure internal {
        (uint rankDiff, uint fileDiff) = getPositionDiff(prevRank, prevFile, newRank, newFile);
        require(fileDiff < 2, "Pawn can only change at most 1 file (while capturing)");

        if(piece.side == PlayerSide.Black) {
            require(prevRank > newRank, "Wrong direction for black pawn");
        } else if(piece.side == PlayerSide.White) {
            require(prevRank < newRank, "Wrong direction for white pawn");
        }

        if(fileDiff == 0) {
            if(piece.hasMadeInitialMove) require(rankDiff == 1, "Pawn can only move one square at a time after initial move");
            else require(rankDiff == 1 || rankDiff == 2, "Pawn can move one or two squares on initial move");
        } else if(fileDiff == 1) {
            require(rankDiff == 1 && board.squares[newRank][newFile].isOccupied, "Pawn can only change file while capturing");
        }
    }

    /// @notice Validate a knight move.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    function validateKnightMove(uint prevRank, uint prevFile, uint newRank, uint newFile) pure internal {
        (uint rankDiff, uint fileDiff) = getPositionDiff(prevRank, prevFile, newRank, newFile);

        require((rankDiff == 2 && fileDiff == 1) || (rankDiff == 1 && fileDiff == 2), "Invalid knight move");
    }

    /// @notice Validate a king move.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param piece the piece that is being moved
    /// @param board the current chessboard state
    function validateKingMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Piece memory piece, Board memory board) internal pure returns(bool) {
        validateDiagonalOrAxialMove(prevRank, prevFile, newRank, newFile, board, false);
        require(!positionIsThreatened(newRank, newFile, board, piece.side), "New position for king is threatened");
    }

    /// @notice Validate a generic diagonal move.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param board the current chessboard state
    /// @param repeating Check as far a distance as possible away from origin square. If false, only allow this move to be a maximum of one square away
    function validateDiagonalMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Board memory board, bool repeating) pure internal {
        (uint rankDiff, uint fileDiff) = getPositionDiff(prevRank, prevFile, newRank, newFile);

        if(repeating) {
            require(rankDiff == fileDiff, "Invalid move (D1)");
        } else {
            require(rankDiff == 1 && fileDiff == 1, "Invalid move (D2)");
        }

        require(!isDiagonalMoveBlocked(prevRank, prevFile, newRank, newFile, board), "Diagonal move is blocked");
    }

    /// @notice Validate a generic axial move.
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param board the current chessboard state
    /// @param repeating Check as far a distance as possible away from origin square. If false, only allow this move to be a maximum of one square away
    function validateAxialMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Board memory board, bool repeating) pure internal {
        (uint rankDiff, uint fileDiff) = getPositionDiff(prevRank, prevFile, newRank, newFile);

        if(repeating) {
            require((rankDiff == 0 && fileDiff != 0) || (rankDiff != 0 && fileDiff == 0), "Invalid move (A1)");
        } else {
            require((rankDiff == 0 && fileDiff == 1) || (rankDiff == 1 && fileDiff == 0), "Invalid move (A2)");
        }

        require(!isAxialMoveBlocked(prevRank, prevFile, newRank, newFile, board), "Axial move is blocked");
    }

    /// @notice Validate a omnidirectional move (for king or queen).
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param board the current chessboard state
    /// @param repeating Check as far a distance as possible away from origin square. If false, only allow this move to be a maximum of one square away
    function validateDiagonalOrAxialMove(uint prevRank, uint prevFile, uint newRank, uint newFile, Board memory board, bool repeating) pure internal {
        (uint rankDiff, uint fileDiff) = getPositionDiff(prevRank, prevFile, newRank, newFile);

        if(repeating) {
            require(
                (rankDiff == 0 && fileDiff != 0) ||
                (rankDiff != 0 && fileDiff == 0) ||
                (rankDiff == fileDiff), 
                "Invalid move (DA1)");
        } else {
            require(
                (rankDiff == 0 && fileDiff == 1) ||
                (rankDiff == 1 && fileDiff == 0) ||
                (rankDiff == 1 && fileDiff == 1),
                "Invalid move (DA2)");
        }

        require(
            !isAxialMoveBlocked(prevRank, prevFile, newRank, newFile, board) &&
            !isDiagonalMoveBlocked(prevRank, prevFile, newRank, newFile, board)
            , "Omnidirectional move is blocked"
        );
    }

    /// @notice Checks to see if another piece is in the way of this axial move
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param board the current chessboard state
    /// @return bool - whether a piece is blocking this move
    function isAxialMoveBlocked(uint prevRank, uint prevFile, uint newRank, uint newFile, Board memory board) pure internal returns(bool) {
        if(prevRank > newRank && prevFile == newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInLowerRankAxial(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevRank < newRank && prevFile == newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInUpperRankAxial(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevFile > newFile && prevRank == newRank) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInLowerFileAxial(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevFile < newFile && prevRank == newRank) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInUpperFileAxial(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        }

        return false;
    }

    /// @notice Checks to see if another piece is in the way of this diagonal move
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param board the current chessboard state
    /// @return bool - whether a piece is blocking this move
    function isDiagonalMoveBlocked(uint prevRank, uint prevFile, uint newRank, uint newFile, Board memory board) pure internal returns(bool) {
        if(prevRank > newRank && prevFile > newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInBackwardLeftDiagonal(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevRank > newRank && prevFile < newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInBackwardRightDiagonal(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevRank < newRank && prevFile < newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInForwardRightDiagonal(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        } else if(prevRank < newRank && prevFile > newFile) {
            (bool found, uint foundRank, uint foundFile,) = findClosestPieceInForwardLeftDiagonal(prevRank, prevFile, board);
            if(found && (foundRank != newRank || foundFile != newFile)) return true;
        }

        return false;
    }

    /// @notice Checks to see if the square given is threatened
    /// @param rank new rank to move this piece to
    /// @param file new file to move this piece to
    /// @param board the current chessboard state
    /// @param side the player colour of the position being checked
    /// @return bool - whether the position/colour is threatened
    function positionIsThreatened(uint rank, uint file, Board memory board, PlayerSide side) internal pure returns(bool) {
        if(knightThreatensPosition(rank, file, board, side)) return true;

        (bool pieceFound, uint pieceRank, uint pieceFile, Piece memory piece) = findClosestPieceInLowerRankAxial(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedAxial(rank, file, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInUpperFileAxial(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedAxial(rank, file, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInUpperRankAxial(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedAxial(rank, file, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInLowerFileAxial(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedAxial(rank, file, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInBackwardLeftDiagonal(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedDiagonal(rank, file, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInBackwardRightDiagonal(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedDiagonal(rank, file, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInForwardRightDiagonal(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedDiagonal(rank, file, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInForwardLeftDiagonal(rank, file, board);
        if(pieceFound && piece.side != side) {
            if(isThreatenedDiagonal(rank, file, pieceRank, pieceFile, piece, side)) return true;
        }
    }

    /// @notice Checks to see if square denoted by `rankPos` and `filePos` is threatened on an axial
    /// @param rankPos the rank of the square we are checking
    /// @param filePos the file of the square we are checking
    /// @param rankToCheck the rank of the threatening piece
    /// @param fileToCheck the file of the threatening piece
    /// @param piece the threatening piece
    /// @return bool - whether the axial is threatened
    function isThreatenedAxial(uint rankPos, uint filePos, uint rankToCheck, uint fileToCheck, Piece memory piece) internal pure returns(bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(rankPos, filePos, rankToCheck, fileToCheck);

        if(rankPosDiff < 2 && filePosDiff < 2 && piece.pieceType == PieceType.King) {
            return true;
        }

        if(piece.pieceType == PieceType.Queen || piece.pieceType == PieceType.Rook) {
            return true;
        }

        return false;
    }

    /// @notice Checks to see if square denoted by `rankPos` and `filePos` is threatened on a diagonal
    /// @param rankPos the rank of the square we are checking
    /// @param filePos the file of the square we are checking
    /// @param rankToCheck the rank of the threatening piece
    /// @param fileToCheck the file of the threatening piece
    /// @param piece the threatening piece
    /// @return bool - whether the diagonal is threatened
    function isThreatenedDiagonal(uint rankPos, uint filePos, uint rankToCheck, uint fileToCheck, Piece memory piece, PlayerSide side) internal pure returns (bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(rankPos, filePos, rankToCheck, fileToCheck);

        if(rankPosDiff < 2 && filePosDiff < 2) {
            if(piece.pieceType == PieceType.King) {
                return true;
            }

            if(rankPosDiff == 1 && filePosDiff == 1 && piece.pieceType == PieceType.Pawn) {
                if(side == PlayerSide.Black && rankToCheck < rankPos) {
                    return true;
                } else if(side == PlayerSide.White && rankToCheck > rankPos) {
                    return true;
                }
            }
        }

        if(piece.pieceType == PieceType.Queen || piece.pieceType == PieceType.Bishop) {
            return true;
        }

        return false;
    }

    /// @notice Finds the closest piece in: descending axial, same file
    /// @param startRank the rank to start checking from
    /// @param file the file which remains constant for this axial
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this axial move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInLowerRankAxial(uint startRank, uint file, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank > 0) {
            uint rank_iter = startRank - 1;

            while (rank_iter >= 0) {
                if(board.squares[rank_iter][file].isOccupied) {
                    return (true, rank_iter, file, board.squares[rank_iter][file].piece);
                }

                if(rank_iter > 0) {
                    rank_iter--;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: same axial, descending file
    /// @param rank the rank which remains constant for this axial
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this axial move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInLowerFileAxial(uint rank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startFile > 0) {
            uint file_iter = startFile - 1;

            while (file_iter >= 0) {
                if(board.squares[rank][file_iter].isOccupied) {
                    return (true, rank, file_iter, board.squares[rank][file_iter].piece);
                }
                if(file_iter > 0) {
                    file_iter--;
                } else {
                    return (false, 0, 0, board.squares[rank][file_iter].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: ascending axial, same file
    /// @param startRank the rank to start checking from
    /// @param file the file which remains constant for this axial
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this axial move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInUpperRankAxial(uint startRank, uint file, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < MAX_RANK) {
            uint rank_iter = startRank + 1;

            while (rank_iter <= MAX_RANK) {
                if(board.squares[rank_iter][file].isOccupied) {
                    return (true, rank_iter, file, board.squares[rank_iter][file].piece);
                }
                if(rank_iter < MAX_RANK) {
                    rank_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: same axial, ascending file
    /// @param rank the rank which remains constant for this axial
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this axial move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInUpperFileAxial(uint rank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startFile < MAX_FILE) {
            uint file_iter = startFile + 1;

            while (file_iter <= MAX_FILE) {
                if(board.squares[rank][file_iter].isOccupied) {
                    return (true, rank, file_iter, board.squares[rank][file_iter].piece);
                }
                if(file_iter < MAX_FILE ){
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank][file_iter].piece);
                }
            }

        }
    }

    /// @notice Finds the closest piece in: descending axial, descending file
    /// @param startRank the rank to start checking from
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this diagonal move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInBackwardLeftDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank > 0 && startFile > 0) {
            uint rank_iter = startRank - 1;
            uint file_iter = startFile - 1;

            while (rank_iter >= 0 && file_iter >= 0) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter > 0 && file_iter > 0) {
                    rank_iter--;
                    file_iter--;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: descending axial, ascending file
    /// @param startRank the rank to start checking from
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this diagonal move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInBackwardRightDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank > 0 && startFile < MAX_FILE) {
            uint rank_iter = startRank - 1;
            uint file_iter = startFile + 1;

            while (rank_iter >= 0 && file_iter <= MAX_FILE) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter > 0 && file_iter < MAX_FILE) {
                    rank_iter--;
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: ascending axial, ascending file
    /// @param startRank the rank to start checking from
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this diagonal move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInForwardRightDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < MAX_RANK && startFile < MAX_FILE) {
            uint rank_iter = startRank + 1;
            uint file_iter = startFile + 1;

            while (rank_iter <= MAX_RANK && file_iter <= MAX_FILE) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter < MAX_RANK && file_iter < MAX_FILE) {
                    rank_iter++;
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    /// @notice Finds the closest piece in: ascending axial, descending file
    /// @param startRank the rank to start checking from
    /// @param startFile the file to start checking from
    /// @param board the current chessboard state
    /// @return bool - Whether a piece was found in the way of this diagonal move
    /// @return uint - rank of piece found
    /// @return uint - file of piece found
    /// @return Piece - the found piece
    function findClosestPieceInForwardLeftDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < MAX_RANK && startFile > 0) {
            uint rank_iter = startRank + 1;
            uint file_iter = startFile - 1;

            while (rank_iter <= MAX_RANK && file_iter >= 0) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter < MAX_RANK && file_iter > 0) {
                    rank_iter++;
                    file_iter--;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    /// @notice Determine if a knight is threatening the given postion
    /// @param rank the rank of the square to check
    /// @param file the file of the square to check
    /// @param board the current chessboard state
    /// @param side the player colour of the piece we are checking
    /// @return bool - Whether a knight is threatening this position
    function knightThreatensPosition(uint rank, uint file, Board memory board, PlayerSide side) internal pure returns (bool) {
        BoardSquare memory squareToCheck;

        if(rank < MAX_RANK && file > 1) {
            squareToCheck = board.squares[rank+1][file-2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank > 0 && file > 1) {
            squareToCheck = board.squares[rank-1][file-2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank > 1 && file > 0) {
            squareToCheck = board.squares[rank-2][file-1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank > 1 && file < MAX_FILE) {
            squareToCheck = board.squares[rank-2][file+1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank < MAX_RANK && file < 6) {
            squareToCheck = board.squares[rank+1][file+2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank > 0 && file < 6) {
            squareToCheck = board.squares[rank-1][file+2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank < 6 && file > 0) {
            squareToCheck = board.squares[rank+2][file-1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rank < 6 && file < MAX_FILE) {
            squareToCheck = board.squares[rank+2][file+1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        return false;
    }

    /// @notice Get the state of the king denoted by the position given
    /// @param rank the current rank of the king
    /// @param file the current file of the king
    /// @param board the current state of the board
    /// @param side the player colour of the king to check
    /// @return bool - whether the king is in check
    /// @return bool - whether the king has been checkmated
    function checkKingState(uint rank, uint file, Board memory board, PlayerSide side) internal pure returns(bool, bool) {
        if(!positionIsThreatened(rank, file, board, side)) {
            return (false, false);
        }

        for(int i1 = -1; i1 <= 1; i1 ++) {
            for(int i2 = -1; i2 <= 1; i2 ++) {
                if(i1 == 0 && i2 == 0) continue;

                int newRankPos = int(rank) + i1;
                int newFilePos = int(file) + i2;

                bool validPositionToCheck = newRankPos >= 0 && newRankPos <= int(MAX_RANK) && newFilePos >= 0 && newFilePos <= int(MAX_FILE);

                if(validPositionToCheck && !positionIsThreatened(uint(newRankPos), uint(newFilePos), board, side)) {
                    return (true, false);
                }
            }
        }

        return (true, true);
    }

    /// @notice Get the change in position of the two positions given
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @return rankPosDiff - the difference in rank of the two positions
    /// @return filePosDiff - the difference in file of the two positions
    function getPositionDiff(uint prevRank, uint prevFile, uint newRank, uint newFile) internal pure returns (uint rankPosDiff, uint filePosDiff) {
        if(prevRank > newRank) {
            rankPosDiff = prevRank - newRank;
        } else if(prevRank < newRank) {
            rankPosDiff = newRank - prevRank;
        } else {
            rankPosDiff = 0;
        }

        if(prevFile > newFile) {
            filePosDiff = prevFile - newFile;
        } else if(prevFile < newFile) {
            filePosDiff = newFile - prevFile;
        } else {
            filePosDiff = 0;
        }
    }

    /// @notice Get the opposite side of the one given
    /// @dev a simple utility function
    /// @param playerSide The player side given
    /// @return PlayerSide - the opposite of the one given
    function getOtherSide(PlayerSide playerSide) pure internal returns(PlayerSide) {
        if(playerSide == PlayerSide.White) return PlayerSide.Black;
        else if(playerSide == PlayerSide.Black) return PlayerSide.White;
        else return PlayerSide.None;
    }
}