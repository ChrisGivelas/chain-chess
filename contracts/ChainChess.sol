pragma solidity ^0.6.0;

contract ChainChess {
    uint8 constant MAX_GAMES_PER_USER = 6;
    
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

    uint gameCount;
    
    mapping(uint => Game) games;
    mapping(address => Game[]) userGames;
    mapping(address => bool) public searchingForNewGame;

    enum PieceType { None, Pawn, Knight, Bishop, Rook, Queen, King }
    enum PlayerSide { None, White, Black }

    struct Piece {
        address owner;
        PieceType pieceType;
        PlayerSide side;
        bool hasMadeInitialMove;
    }

    struct Player {
        address playerAddress;
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
        Piece[] eliminatedPieces;
        Player player1;
        Player player2;
        PlayerSide inCheck;
    }

    struct Game {
        uint gameId;
        Board board;
        PlayerSide currentTurn;
        bool started;
        bool ended;
        address winner;
    }

    modifier verifySenderIsEither(address address1, address address2) {
        require(msg.sender == address1 || msg.sender == address2, "User is not a part of this game");
        _;
    }

    modifier gameExists(uint gameId) {
        require(games[gameId].board.player1.playerAddress != address(0), "Game does not exist");
        _;
    }

    modifier maxGamesNotReached(address player) {
        require(userGames[player].length < MAX_GAMES_PER_USER, "User already has the maximum number of games started");
        _;
    }

    constructor() public {
        gameCount = 0;
    }

    function declareSearchingForGame() public maxGamesNotReached(msg.sender) returns(bool) {
        require(!searchingForNewGame[msg.sender], "User already searching for new game");

        searchingForNewGame[msg.sender] = true;

        return true;
    }

    function acceptGame(address otherPlayer) public maxGamesNotReached(msg.sender) returns(bool) {
        require(searchingForNewGame[otherPlayer], "Game does not exist");
        searchingForNewGame[otherPlayer] = false;

        if(searchingForNewGame[msg.sender]) {
            searchingForNewGame[msg.sender] = false;
        }

        Game storage newGame = games[gameCount];

        createGame(gameCount, msg.sender, otherPlayer, newGame);

        gameCount++;
        
        Game[] storage player1Games = userGames[msg.sender];
        player1Games.push(newGame);

        Game[] storage player2Games = userGames[otherPlayer];
        player2Games.push(newGame);
    }

    function movePiece(uint gameId, uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos) public 
    gameExists(gameId)
    verifySenderIsEither(games[gameId].board.player1.playerAddress, games[gameId].board.player2.playerAddress) returns (bool) {
        Game storage game = games[gameId];
        Player memory currentPlayer = getCurrentPlayer(game.board);
        Player memory otherPlayer = getOtherPlayer(game.board);
        BoardSquare storage selectedSquare = game.board.squares[prevRankPos][prevFilePos];
        BoardSquare storage squareToMoveTo = game.board.squares[newRankPos][newFilePos];

        require(selectedSquare.isOccupied, "No piece found at this location");
        require(selectedSquare.piece.owner == msg.sender, "Piece is not owned by sender");
        require(isValidMove(prevRankPos, prevFilePos, newRankPos, newFilePos, selectedSquare.piece, game.board), "Invalid move");

        // If a piece was eliminated, add it to the eliminatedPieces array
        if(squareToMoveTo.isOccupied) {
            game.board.eliminatedPieces.push(squareToMoveTo.piece);
        }

        // Remove piece from previous location...
        selectedSquare.isOccupied = false;
        selectedSquare.piece.owner = address(0);

        // ...and move it to new square
        squareToMoveTo.isOccupied = true;
        squareToMoveTo.piece.owner = msg.sender;
        squareToMoveTo.piece.pieceType = selectedSquare.piece.pieceType;
        squareToMoveTo.piece.side = selectedSquare.piece.side;
        squareToMoveTo.piece.hasMadeInitialMove = true;

        // If this move does not take the players king out of check, then revert this move
        if(game.board.inCheck == currentPlayer.side) {
            (bool inCheck,) = getKingState(game, currentPlayer);

            if(inCheck) {
                revert("Player is in check. Must protect king");
            }
        }

        // Check if the game is done
        (bool inCheck, bool checkMated) = getKingState(game, otherPlayer);

        if(checkMated) {
            game.ended = true;
            game.winner = msg.sender;
        } else {
            if(inCheck) {
                game.board.inCheck = otherPlayer.side;
            }

            // Update king location if need be
            if(selectedSquare.piece.pieceType == PieceType.King) {
                currentPlayer.kingRankPos = newRankPos;
                currentPlayer.kingFilePos = newFilePos;
            }

            // Update player turn
            game.currentTurn = otherPlayer.side;
        }

        return true;
    }

    function createGame(uint gameId, address player1Address, address player2Address, Game storage newGame) internal {
        //First coordinate represents 1 - 8 ranks (rows), second represents a - h files (columns)
        for(uint8 rank_iter = 0; rank_iter <= 7; rank_iter++) {
            for(uint8 file_iter = 0; file_iter <= 7; file_iter++) {
                if(defaultRankOwnership[rank_iter] != PlayerSide.None) {
                    newGame.board.squares[rank_iter][file_iter].isOccupied = true;
                    newGame.board.squares[rank_iter][file_iter].piece.owner = defaultRankOwnership[rank_iter] == PlayerSide.White ? player1Address : player2Address;
                    newGame.board.squares[rank_iter][file_iter].piece.pieceType = default2dPieceLayout[rank_iter][file_iter];
                    newGame.board.squares[rank_iter][file_iter].piece.side = defaultRankOwnership[rank_iter];
                    newGame.board.squares[rank_iter][file_iter].piece.hasMadeInitialMove = false;

                    if(newGame.board.squares[rank_iter][file_iter].piece.pieceType == PieceType.King) {
                        if(defaultRankOwnership[rank_iter] == PlayerSide.White) {
                            newGame.board.player1.playerAddress = player1Address;
                            newGame.board.player1.side = defaultRankOwnership[rank_iter];
                            newGame.board.player1.kingRankPos = rank_iter;
                            newGame.board.player1.kingFilePos = file_iter;
                        } else if (defaultRankOwnership[rank_iter] == PlayerSide.Black) {
                            newGame.board.player2.playerAddress = player2Address;
                            newGame.board.player2.side = defaultRankOwnership[rank_iter];
                            newGame.board.player2.kingRankPos = rank_iter;
                            newGame.board.player2.kingFilePos = file_iter;
                        }
                    }
                }
            }
        }

        newGame.gameId = gameId;
        newGame.started = true;
        newGame.ended = false;
        newGame.currentTurn = PlayerSide.White;
        newGame.winner = address(0);
    }

    int8[2][8] possibleKingMoves = [
        [-1,-1],
        [-1,int8(0)],
        [-1,int8(1)],
        [int8(0),int8(1)],
        [int8(1),int8(1)],
        [int8(1),0],
        [int8(1),-1],
        [int8(0),-1]
    ];

    function getKingState(Game memory game, Player memory player) view internal returns(bool, bool) {
        uint8 rankPos;
        uint8 filePos;
        
        rankPos = player.kingRankPos;
        filePos = player.kingFilePos;

        if(!positionIsThreatened(rankPos, filePos, game.board, player.side)) {
            return (false, false);
        }

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

    function isValidMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, Piece memory piece, Board memory board) view internal returns(bool) {
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

        // Kill move
        if(filePosDiff == 1 && rankPosDiff == 1) {
            return board.squares[newRankPos][newFilePos].isOccupied;
        }

        return false;
    }

    function isValidKingMove(uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos, Piece memory piece, Board memory board) view internal returns(bool) {
        if(isValidAxialMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false) || isValidDiagonalMove(prevRankPos, prevFilePos, newRankPos, newFilePos, false)) {
            return !positionIsThreatened(newRankPos, newFilePos, board, piece.side);
        }
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

    int8[2][8] possibleKnightMoves = [
        [-2,-1],
        [-2,int8(1)],
        [-1,int8(2)],
        [int8(1),int8(2)],
        [int8(2),int8(1)],
        [int8(2),-1],
        [int8(1),-2],
        [-1,-2]
    ];

    function knightThreatensPosition(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side) view internal returns (bool) {
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

    function positionIsThreatened(uint8 rankPos, uint8 filePos, Board memory board, PlayerSide side) view internal returns(bool) {
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

    function getCurrentPlayer(Board memory board) view internal returns(Player memory) {
        return board.player1.playerAddress == msg.sender ? board.player1 : board.player2;
    }

    function getOtherPlayer(Board memory board) view internal returns(Player memory) {
        return board.player1.playerAddress == msg.sender ? board.player2 : board.player1;
    }
}
