pragma solidity ^0.6.0;

import "./StringUtils.sol";

contract BaseGame {
    uint maxGamesPerUser;
    uint gameCount;

    constructor(uint maxGames) public {
        maxGamesPerUser = maxGames;
        gameCount = 0;
    }

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

    struct PlayerProfile {
        uint[] activeGames;
        uint[] completedGames;
        uint wins;
        uint losses;
    }

    mapping(uint => Game) games;
    mapping(address => PlayerProfile) players;

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

    function validateMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory pieceToMove, Board memory board) internal pure {
        require(!(board.squares[newRankPos][newFilePos].isOccupied && board.squares[newRankPos][newFilePos].piece.side == pieceToMove.side), "New square has one of player's own pieces");

        if(pieceToMove.pieceType == PieceType.Pawn) {
            validatePawnMove(prevRankPos, prevFilePos, newRankPos, newFilePos, pieceToMove, board);
        } else if (pieceToMove.pieceType == PieceType.Knight) { 
            validateKnightMove(prevRankPos, prevFilePos, newRankPos, newFilePos);
        } else if (pieceToMove.pieceType == PieceType.Bishop) {
            validateDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (pieceToMove.pieceType == PieceType.Rook) {
            validateAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (pieceToMove.pieceType == PieceType.Queen) {
            validateAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
            validateDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, true);
        } else if (pieceToMove.pieceType == PieceType.Knight) {
            validateKingMove(prevRankPos, prevFilePos, newRankPos, newFilePos, pieceToMove, board);
        }
    }

    function validateDiagonalMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, bool repeating) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        require(!(rankPosDiff == 0 || filePosDiff == 0), "Invalid move (D1)"); 

        if(repeating) {
            require(rankPosDiff == filePosDiff, "Invalid move (D2)");
        } else {
            require(rankPosDiff == 1 && filePosDiff == 1, "Invalid move (D3)");
        }
    }

    function validateAxialMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, bool repeating) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(repeating) {
            require(!((rankPosDiff == 0 && filePosDiff != 0) || (rankPosDiff != 0 && filePosDiff == 0)),"Invalid move (A1)");
        } else {
            require(!((rankPosDiff == 0 && filePosDiff == 1) || (rankPosDiff == 1 && filePosDiff == 0)), "Invalid move (A2)");
        }
    }

    function validateKnightMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) pure internal {
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        require(!((rankPosDiff == 2 && filePosDiff == 1) || (rankPosDiff == 1 && filePosDiff == 2)), "Invalid knight move");
    }

    function validatePawnMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory piece, Board memory board) pure internal {
        if(piece.side == PlayerSide.Black) {
            require(prevRankPos > newRankPos, "Wrong direction for black pawn");
        } else if(piece.side == PlayerSide.White) {
            require(prevRankPos < newRankPos, "Wrong direction for white pawn");
        }
        
        (uint rankPosDiff, uint filePosDiff) = getPositionDiff(prevRankPos, prevFilePos, newRankPos, newFilePos);

        if(filePosDiff == 0) {
            if(piece.hasMadeInitialMove) require(rankPosDiff == 1, "Pawn can only move one square at a time after initial move");
            else require(rankPosDiff == 1 || rankPosDiff == 2, "Pawn can move one or two squares on initial move");
        } else if(filePosDiff == 1) {
            require(rankPosDiff == 1 && board.squares[newRankPos][newFilePos].isOccupied, "Pawn can only change files while capturing");
        }
    }

    function validateKingMove(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, Piece memory piece, Board memory board) internal pure returns(bool) {
        validateAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false);
        validateDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false);
        require(!positionIsThreatened(newRankPos, newFilePos, board, piece.side), "New position for king is threatened");
    }

    function positionIsThreatened(uint rankPos, uint filePos, Board memory board, PlayerSide side) internal pure returns(bool) {
        if(axialsAreThreatened(rankPos, filePos, board, side)) return true;
        if(diagonalsAreThreatened(rankPos, filePos, board, side)) return true;
        // Check for threatening knight
        if(knightThreatensPosition(rankPos, filePos, board, side)) return true;
    }

    function axialsAreThreatened(uint rankPos, uint filePos, Board memory board, PlayerSide side) pure internal returns(bool) {
        BoardSquare memory square;

        for(uint i1 = 0; i1 <= 7; i1++) {
            for(uint i2 = 0; i2 <= 7; i2++) {
                if((i1 != rankPos && i2 != filePos) || (i1 == rankPos && i2 == filePos)) continue;

                square = board.squares[i1][i2];

                if(square.isOccupied) {
                    if(square.piece.side != side) {
                        if(square.piece.pieceType == PieceType.Queen || square.piece.pieceType == PieceType.Rook)
                            return true;
                    } else {
                        break;
                    }
                }
            }
        }

        return false;
    }

    function diagonalsAreThreatened(uint rankPos, uint filePos, Board memory board, PlayerSide side) pure internal returns(bool) {
        BoardSquare memory square;

        for(uint i1 = 0; i1 <= 7; i1++) {
            for(uint i2 = 0; i2 <= 7; i2++) {
                if((i1 == rankPos && i2 != filePos) || (i1 != rankPos && i2 == filePos) || (i1 == rankPos && i2 == filePos)) continue;

                (uint rankPosDiff, uint filePosDiff) = getPositionDiff(rankPos, filePos, i1, i2);

                if(rankPosDiff != filePosDiff) continue;

                square = board.squares[i1][i2];

                if(square.isOccupied) {
                    if(square.piece.side != side) {
                        if(
                            rankPosDiff == 1 &&
                            filePosDiff == 1 &&
                            square.piece.pieceType == PieceType.Pawn &&
                            ((side == PlayerSide.White && i1 > rankPos) || (side == PlayerSide.Black && i1 < rankPos))) {
                            return true;
                        }
                        
                        if(square.piece.pieceType == PieceType.Queen || square.piece.pieceType == PieceType.Rook) {
                            return true;
                        }
                    } else {
                        break;
                    }
                }
            }
        }

        return false;
    }

    function knightThreatensPosition(uint rankPos, uint filePos, Board memory board, PlayerSide side) internal pure returns (bool) {
        for(int i1 = -2; i1 <= 2; i1++) {
            for(int i2 = -2; i2 <= 2; i2++) {
                if(i1 == 0 || i2 == 0 || i1 == i2 || i1 + i2 == 0) continue;

                int newRankPos = int(rankPos) + i1;
                int newFilePos = int(filePos) + i2;

                bool validPositionToCheck = newRankPos >= 0 && newRankPos <= 7 && newFilePos >= 0 && newFilePos <= 7;

                if(validPositionToCheck) {
                    BoardSquare memory squareToCheck = board.squares[uint(int(rankPos) + i1)][uint(int(filePos) + i2)];
                    if(squareToCheck.isOccupied && squareToCheck.piece.pieceType == PieceType.Knight && squareToCheck.piece.side != side){
                        return true;
                    }
                }
            }
        }

        return false;
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
        } else if(prevFilePos > newFilePos) {
            filePosDiff = newFilePos - prevFilePos;
        } else {
            filePosDiff = 0;
        }
    }

    // =========================== Getters ===========================

    function getOtherSide(PlayerSide playerSide) pure internal returns(PlayerSide) {
        if(playerSide == PlayerSide.White) return PlayerSide.Black;
        else if(playerSide == PlayerSide.Black) return PlayerSide.Black;
        else return PlayerSide.None;
    }

    function getGameByGameId(uint gameId) public view returns(uint, string memory, PlayerSide , bool, bool, address, PlayerSide, address, PlayerSide, address) {
        require(gameId <= gameCount, "Game does not exist");
        require(games[gameId].board.players[msg.sender].side != PlayerSide.None, "User is not a part of this game.");

        Game storage game = games[gameId];

        return (
            game.gameId,
            game.moveHistory,
            game.currentTurn,
            game.started,
            game.ended,
            game.board.playerSides[uint(PlayerSide.White)],
            PlayerSide.White,
            game.board.playerSides[uint(PlayerSide.Black)],
            PlayerSide.Black,
            game.winner
        );
    }

    function getGameByOpponent(address opponentAddress) public view returns(uint, string memory, PlayerSide, bool, bool, address, PlayerSide, address, PlayerSide, address) {
        uint[] storage activeGames = players[msg.sender].activeGames;

        for(uint i = 0; i < activeGames.length; i++) {
            if(games[activeGames[i]].board.players[msg.sender].side != PlayerSide.None && games[activeGames[i]].board.players[opponentAddress].side != PlayerSide.None) {
                Game storage game = games[activeGames[i]];
                return (
                    game.gameId,
                    game.moveHistory,
                    game.currentTurn,
                    game.started,
                    game.ended,
                    game.board.playerSides[uint(PlayerSide.White)],
                    PlayerSide.White,
                    game.board.playerSides[uint(PlayerSide.Black)],
                    PlayerSide.Black,
                    game.winner
                );
            }
        }
    }
    
    function getActiveGames() public view returns(address[] memory opponentAddresses, uint[] memory gameIds) {
        uint[] storage activeGames = players[msg.sender].activeGames;
        
        for(uint i = 0; i < activeGames.length; i++) {
            Game storage game = games[activeGames[i]];

            opponentAddresses[i] = game.board.playerSides[uint(getOtherSide(game.board.players[msg.sender].side))];
            gameIds[i] = game.gameId;
        }
    }

    string[8] fileIdMapping = ["a","b","c","d","e","f","g","h"];
    string[8] rankIdMapping = ["1","2","3","4","5","6","7","8"];
    string[7] pieceIdMapping = ["NONE", "p", "n", "b", "r", "q", "k" ];

    function getMoveHistoryEntry(uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos, uint pieceEnumValue, bool isCapture) internal view returns(string memory) {
        return StringUtils.strConcat(
            pieceIdMapping[pieceEnumValue],
            fileIdMapping[prevFilePos],
            rankIdMapping[prevRankPos],
            isCapture ? "x" : "",
            fileIdMapping[newFilePos],
            rankIdMapping[newRankPos]
        );
    }
}