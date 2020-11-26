pragma solidity ^0.6.0;

library Chess {
    enum PieceType { None, Pawn, Knight, Bishop, Rook, Queen, King }
    enum PlayerSide { None, White, Black }

    struct Piece {
        PieceType pieceType;
        PlayerSide side;
        bool hasMadeInitialMove;
    }

    struct Player {
        PlayerSide side;
        uint kingRankPos;
        uint kingFilePos;
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

    function validateMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory pieceToMove, Board memory board) internal pure {
        require(!(board.squares[newRankPos][newFilePos].isOccupied && board.squares[newRankPos][newFilePos].piece.side == pieceToMove.side), "New square has one of player's own pieces");

        if(pieceToMove.pieceType == PieceType.Pawn) {
            validatePawnMove(prevRankPos, prevFilePos, newRankPos, newFilePos, pieceToMove, board);
        } else if (pieceToMove.pieceType == PieceType.Knight) { 
            validateKnightMove(prevRankPos, prevFilePos, newRankPos, newFilePos);  
        }  else if (pieceToMove.pieceType == PieceType.Knight) {
            validateKingMove(prevRankPos, prevFilePos, newRankPos, newFilePos, pieceToMove, board);
        } else if (pieceToMove.pieceType == PieceType.Bishop) {
            validateDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, board, true);
        } else if (pieceToMove.pieceType == PieceType.Rook) {
            validateAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, board, true);
        } else if (pieceToMove.pieceType == PieceType.Queen) {
            validateDiagonalOrAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, board, true);
        }
    }

    function validatePawnMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory piece, Board memory board) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(piece.side == PlayerSide.Black) {
            require(prevRankPos > newRankPos, "Wrong direction for black pawn");
        } else if(piece.side == PlayerSide.White) {
            require(prevRankPos < newRankPos, "Wrong direction for white pawn");
        }

        require(filePosDiff < 2, "Pawn can only change at most 1 file (while capturing)");

        if(filePosDiff == 0) {
            if(piece.hasMadeInitialMove) require(rankPosDiff == 1, "Pawn can only move one square at a time after initial move");
            else require(rankPosDiff == 1 || rankPosDiff == 2, "Pawn can move one or two squares on initial move");
        } else if(filePosDiff == 1) {
            require(rankPosDiff == 1 && board.squares[newRankPos][newFilePos].isOccupied, "Pawn can only change file while capturing");
        }
    }

    function validateKnightMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        require((rankPosDiff == 2 && filePosDiff == 1) || (rankPosDiff == 1 && filePosDiff == 2), "Invalid knight move");
    }

    function validateKingMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory piece, Board memory board) internal pure returns(bool) {
        validateDiagonalOrAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, board, false);
        require(!positionIsThreatened(newRankPos, newFilePos, board, piece.side), "New position for king is threatened");
    }

    function validateDiagonalMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Board memory board, bool repeating) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(repeating) {
            require(rankPosDiff == filePosDiff, "Invalid move (D1)");
        } else {
            require(rankPosDiff == 1 && filePosDiff == 1, "Invalid move (D2)");
        }

        require(!isDiagonalMoveBlocked(prevRankPos, prevFilePos, newRankPos, newFilePos, board), "Diagonal move is blocked");
    }

    function validateAxialMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Board memory board, bool repeating) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(repeating) {
            require((rankPosDiff == 0 && filePosDiff != 0) || (rankPosDiff != 0 && filePosDiff == 0), "Invalid move (A1)");
        } else {
            require((rankPosDiff == 0 && filePosDiff == 1) || (rankPosDiff == 1 && filePosDiff == 0), "Invalid move (A2)");
        }

        require(!isAxialMoveBlocked(prevRankPos, prevFilePos, newRankPos, newFilePos, board), "Axial move is blocked");
    }

    function validateDiagonalOrAxialMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Board memory board, bool repeating) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(repeating) {
            require(
                (rankPosDiff == 0 && filePosDiff != 0) ||
                (rankPosDiff != 0 && filePosDiff == 0) ||
                (rankPosDiff == filePosDiff), 
                "Invalid move (DA1)");
        } else {
            require(
                (rankPosDiff == 0 && filePosDiff == 1) ||
                (rankPosDiff == 1 && filePosDiff == 0) ||
                (rankPosDiff == 1 && filePosDiff == 1),
                "Invalid move (DA2)");
        }

        require(
            !isAxialMoveBlocked(prevRankPos, prevFilePos, newRankPos, newFilePos, board) &&
            !isDiagonalMoveBlocked(prevRankPos, prevFilePos, newRankPos, newFilePos, board)
            , "Omnidirectional move is blocked"
        );
    }

    function isAxialMoveBlocked(uint startRank, uint startFile, uint endRank, uint endFile, Board memory board) pure internal returns(bool) {
        bool found;
        uint foundRank;
        uint foundFile;

        if(startRank > endRank && startFile == endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInLowerRankAxial(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startRank < endRank && startFile == endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInUpperRankAxial(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startFile > endFile && startRank == endRank) {
            (found, foundRank, foundFile,) = findClosestPieceInLowerFileAxial(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startFile < endFile && startRank == endRank) {
            (found, foundRank, foundFile,) = findClosestPieceInUpperFileAxial(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        }

        return false;
    }

    function isDiagonalMoveBlocked(uint startRank, uint startFile, uint endRank, uint endFile, Board memory board) pure internal returns(bool) {
        bool found;
        uint foundRank;
        uint foundFile;

        if(startRank > endRank && startFile > endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInBackwardLeftDiagonal(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startRank > endRank && startFile < endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInBackwardRightDiagonal(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startRank < endRank && startFile < endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInForwardRightDiagonal(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        } else if(startRank < endRank && startFile > endFile) {
            (found, foundRank, foundFile,) = findClosestPieceInForwardLeftDiagonal(startRank, startFile, board);
            if(found && (foundRank != endRank || foundFile != endFile)) return true;
        }

        return false;
    }

    function positionIsThreatened(uint rankPos, uint filePos, Board memory board, PlayerSide side) internal pure returns(bool) {
        // Check for threatening knight
        if(knightThreatensPosition(rankPos, filePos, board, side)) return true;

        (bool pieceFound, uint pieceRank, uint pieceFile, Piece memory piece) = findClosestPieceInLowerRankAxial(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningAxial(rankPos, filePos, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInUpperFileAxial(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningAxial(rankPos, filePos, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInUpperRankAxial(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningAxial(rankPos, filePos, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInLowerFileAxial(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningAxial(rankPos, filePos, pieceRank, pieceFile, piece)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInBackwardLeftDiagonal(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningDiagonal(rankPos, filePos, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInBackwardRightDiagonal(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningDiagonal(rankPos, filePos, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInForwardRightDiagonal(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningDiagonal(rankPos, filePos, pieceRank, pieceFile, piece, side)) return true;
        }
        (pieceFound, pieceRank, pieceFile, piece) = findClosestPieceInForwardLeftDiagonal(rankPos, filePos, board);
        if(pieceFound && piece.side != side) {
            if(isThreateningDiagonal(rankPos, filePos, pieceRank, pieceFile, piece, side)) return true;
        }
    }

    function isThreateningAxial(uint rankPos, uint filePos, uint pieceRank, uint pieceFile, Piece memory piece) internal pure returns(bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(rankPos, filePos, pieceRank, pieceFile);

        if(rankPosDiff < 2 && filePosDiff < 2 && piece.pieceType == PieceType.King) {
            return true;
        }

        if(piece.pieceType == PieceType.Queen || piece.pieceType == PieceType.Rook) {
            return true;
        }

        return false;
    }

    function isThreateningDiagonal(uint rankPos, uint filePos, uint pieceRank, uint pieceFile, Piece memory piece, PlayerSide side) internal pure returns (bool) {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(rankPos, filePos, pieceRank, pieceFile);

        if(rankPosDiff < 2 && filePosDiff < 2) {
            if(piece.pieceType == PieceType.King) {
                return true;
            }

            if(rankPosDiff == 1 && filePosDiff == 1 && piece.pieceType == PieceType.Pawn) {
                if(side == PlayerSide.Black && pieceRank < rankPos) {
                    return true;
                } else if(side == PlayerSide.White && pieceRank > rankPos) {
                    return true;
                }
            }
        }

        if(piece.pieceType == PieceType.Queen || piece.pieceType == PieceType.Bishop) {
            return true;
        }

        return false;
    }

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

    function findClosestPieceInUpperRankAxial(uint startRank, uint file, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < 7) {
            uint rank_iter = startRank + 1;

            while (rank_iter <= 7) {
                if(board.squares[rank_iter][file].isOccupied) {
                    return (true, rank_iter, file, board.squares[rank_iter][file].piece);
                }
                if(rank_iter < 7) {
                    rank_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file].piece);
                }
            }
        }
    }

    function findClosestPieceInUpperFileAxial(uint rank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startFile < 7) {
            uint file_iter = startFile + 1;

            while (file_iter <= 7) {
                if(board.squares[rank][file_iter].isOccupied) {
                    return (true, rank, file_iter, board.squares[rank][file_iter].piece);
                }
                if(file_iter < 7 ){
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank][file_iter].piece);
                }
            }

        }
    }

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

    function findClosestPieceInBackwardRightDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank > 0 && startFile < 7) {
            uint rank_iter = startRank - 1;
            uint file_iter = startFile + 1;

            while (rank_iter >= 0 && file_iter <= 7) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter > 0 && file_iter < 7) {
                    rank_iter--;
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    function findClosestPieceInForwardRightDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < 7 && startFile < 7) {
            uint rank_iter = startRank + 1;
            uint file_iter = startFile + 1;

            while (rank_iter <= 7 && file_iter <= 7) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter < 7 && file_iter < 7) {
                    rank_iter++;
                    file_iter++;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    function findClosestPieceInForwardLeftDiagonal(uint startRank, uint startFile, Board memory board) pure internal returns(bool, uint, uint, Piece memory) {
        if(startRank < 7 && startFile > 0) {
            uint rank_iter = startRank + 1;
            uint file_iter = startFile - 1;

            while (rank_iter <= 7 && file_iter >= 0) {
                if(board.squares[rank_iter][file_iter].isOccupied) {
                    return (true, rank_iter, file_iter, board.squares[rank_iter][file_iter].piece);
                }
                if(rank_iter < 7 && file_iter > 0) {
                    rank_iter++;
                    file_iter--;
                } else {
                    return (false, 0, 0, board.squares[rank_iter][file_iter].piece);
                }
            }
        }
    }

    function knightThreatensPosition(uint rankPos, uint filePos, Board memory board, PlayerSide side) internal pure returns (bool) {
        BoardSquare memory squareToCheck;
        if(rankPos < 7 && filePos > 1) {
            squareToCheck = board.squares[rankPos+1][filePos-2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos > 0 && filePos > 1) {
            squareToCheck = board.squares[rankPos-1][filePos-2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos > 1 && filePos > 0) {
            squareToCheck = board.squares[rankPos-2][filePos-1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos > 1 && filePos < 7) {
            squareToCheck = board.squares[rankPos-2][filePos+1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos < 7 && filePos < 6) {
            squareToCheck = board.squares[rankPos+1][filePos+2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos > 0 && filePos < 6) {
            squareToCheck = board.squares[rankPos-1][filePos+2];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos < 6 && filePos > 0) {
            squareToCheck = board.squares[rankPos+2][filePos-1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }

        if(rankPos < 6 && filePos < 7) {
            squareToCheck = board.squares[rankPos+2][filePos+1];
            if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side) return true;
        }
        return false;
    }

    function checkKingState(uint rankPos, uint filePos, Game memory game, Player memory player) internal pure returns(bool, bool) {
        if(!positionIsThreatened(rankPos, filePos, game.board, player.side)) {
            return (false, false);
        }

        for(int i1 = -1; i1 <= 1; i1 ++) {
            for(int i2 = -1; i2 <= 1; i2 ++) {
                if(i1 == 0 && i2 == 0) continue;

                int newRankPos = int(rankPos) + i1;
                int newFilePos = int(filePos) + i2;

                bool validPositionToCheck = newRankPos >= 0 && newRankPos <= 7 && newFilePos >= 0 && newFilePos <= 7;

                if(validPositionToCheck && !positionIsThreatened(uint(newRankPos), uint(newFilePos), game.board, player.side)) {
                    return (true, false);
                }
            }
        }

        return (true, true);
    }

    function getPositionDiff(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) internal pure returns (uint rankPosDiff, uint filePosDiff) {
        if(prevRankPos > newRankPos) {
            rankPosDiff = prevRankPos - newRankPos;
        } else if(prevRankPos < newRankPos) {
            rankPosDiff = newRankPos - prevRankPos;
        } else {
            rankPosDiff = 0;
        }

        if(prevFilePos > newFilePos) {
            filePosDiff = prevFilePos - newFilePos;
        } else if(prevFilePos < newFilePos) {
            filePosDiff = newFilePos - prevFilePos;
        } else {
            filePosDiff = 0;
        }
    }

    function getOtherSide(PlayerSide playerSide) pure internal returns(PlayerSide) {
        if(playerSide == PlayerSide.White) return PlayerSide.Black;
        else if(playerSide == PlayerSide.Black) return PlayerSide.White;
        else return PlayerSide.None;
    }
}