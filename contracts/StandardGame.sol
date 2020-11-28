pragma solidity ^0.6.0;

import "./Chess.sol";
import "./StringUtils.sol";

contract StandardGame {
    address[] public searchingForNewGame;
    uint maxGamesPerUser;
    uint gameCount;
    mapping(uint => Chess.Game) games;
    mapping(address => PlayerProfile) players;

    event MovePiece(uint indexed gameId, address indexed player, string moveHistory);

    struct PlayerProfile {
        uint[] activeGames;
        uint[] completedGames;
        uint wins;
        uint losses;
    }

    constructor(uint maxGames) public {
        maxGamesPerUser = maxGames;
        gameCount = 0;
    }

    modifier maxGamesNotReached(address playerAddress) {
        require(players[playerAddress].activeGames.length < maxGamesPerUser, "User already has the maximum number of games started");
        _;
    }

    function declareSearchingForGame() public maxGamesNotReached(msg.sender) returns(bool) {
        require(!userIsSearching(msg.sender), "User already searching for new game");

        searchingForNewGame.push(msg.sender);

        return true;
    }

    function userIsSearching(address playerAddress) public view returns(bool) {
        for(uint i = 0; i < searchingForNewGame.length; i++) {
            if(searchingForNewGame[i] == playerAddress) {
                return true;
            }
        }

        return false;
    }

    function acceptGame(address otherPlayer) public maxGamesNotReached(msg.sender) returns(uint) {
        require(userIsSearching(otherPlayer), "Game does not exist");
        require(msg.sender != otherPlayer, "Two different players are required to start a new game");
        
        Chess.Game storage newGame = games[gameCount];

        initializeGame(gameCount, msg.sender, otherPlayer, newGame);
        
        players[msg.sender].activeGames.push(newGame.gameId);
        players[otherPlayer].activeGames.push(newGame.gameId);

        gameCount++;

        stopSearchingForGame(otherPlayer);
        if(userIsSearching(msg.sender)) {
            stopSearchingForGame(msg.sender);
        }

        return newGame.gameId;
    }

    function stopSearchingForGame(address playerAddress) internal {
        for(uint i = 0; i < searchingForNewGame.length; i++) {
            if(searchingForNewGame[i] == playerAddress) {
                searchingForNewGame[i] = searchingForNewGame[searchingForNewGame.length - 1];
                searchingForNewGame.pop();
            }
        }
    }

    function initializeGame(uint gameId, address player1Address, address player2Address, Chess.Game storage newGame) internal {
        Chess.Board storage board = newGame.board;
        board.playerSides[uint(Chess.PlayerSide.White)] = player1Address;
        board.playerSides[uint(Chess.PlayerSide.Black)] = player2Address;

        board.players[player1Address].side = Chess.PlayerSide.White;
        board.players[player1Address].kingRankPos = 0;
        board.players[player1Address].kingFilePos = 4;

        board.players[player2Address].side = Chess.PlayerSide.Black;
        board.players[player2Address].kingRankPos = 7;
        board.players[player2Address].kingFilePos = 4;

        for(uint i = 0; i <= 7; i++) {
            for(uint j = 0; j <= 7; j++) {
                setInitialPositionForPiece(i, j, board.squares[i][j]);
            }
        }

        newGame.gameId = gameId;
        newGame.currentTurn = Chess.PlayerSide.White;
        newGame.started = true;
        newGame.ended = false;
        newGame.winner = address(0);
        newGame.moveHistory = "";
        newGame.moveCount = 0;
    }

    function setInitialPositionForPiece(uint rank, uint file, Chess.BoardSquare storage square) internal returns (Chess.Piece memory) {
        Chess.Piece memory temp;

        if(rank == 0) {
            if(file == 0) temp = Chess.Piece(Chess.PieceType.Rook, Chess.PlayerSide.White, false);
            if(file == 1) temp = Chess.Piece(Chess.PieceType.Knight, Chess.PlayerSide.White, false);
            if(file == 2) temp = Chess.Piece(Chess.PieceType.Bishop, Chess.PlayerSide.White, false);
            if(file == 3) temp = Chess.Piece(Chess.PieceType.Queen, Chess.PlayerSide.White, false);
            if(file == 4) temp = Chess.Piece(Chess.PieceType.King, Chess.PlayerSide.White, false);
            if(file == 5) temp = Chess.Piece(Chess.PieceType.Bishop, Chess.PlayerSide.White, false);
            if(file == 6) temp = Chess.Piece(Chess.PieceType.Knight, Chess.PlayerSide.White, false);
            if(file == 7) temp = Chess.Piece(Chess.PieceType.Rook, Chess.PlayerSide.White, false);
        } else if(rank == 1) {
            temp = Chess.Piece(Chess.PieceType.Pawn, Chess.PlayerSide.White, false);
        } else if(rank == 6) {
            temp = Chess.Piece(Chess.PieceType.Pawn, Chess.PlayerSide.Black, false);
        } else if(rank == 7) {
            if(file == 0) temp = Chess.Piece(Chess.PieceType.Rook, Chess.PlayerSide.Black, false);
            if(file == 1) temp = Chess.Piece(Chess.PieceType.Knight, Chess.PlayerSide.Black, false);
            if(file == 2) temp = Chess.Piece(Chess.PieceType.Bishop, Chess.PlayerSide.Black, false);
            if(file == 3) temp = Chess.Piece(Chess.PieceType.Queen, Chess.PlayerSide.Black, false);
            if(file == 4) temp = Chess.Piece(Chess.PieceType.King, Chess.PlayerSide.Black, false);
            if(file == 5) temp = Chess.Piece(Chess.PieceType.Bishop, Chess.PlayerSide.Black, false);
            if(file == 6) temp = Chess.Piece(Chess.PieceType.Knight, Chess.PlayerSide.Black, false);
            if(file == 7) temp = Chess.Piece(Chess.PieceType.Rook, Chess.PlayerSide.Black, false);
        }

        square.piece.pieceType = temp.pieceType;
        square.piece.side = temp.side;
        square.piece.hasMadeInitialMove = temp.hasMadeInitialMove;

        if(rank == 0 || rank == 1 || rank == 6 || rank == 7) {
            square.isOccupied = true;
        }
    }

    function movePiece(uint gameId, uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) public returns (string memory) {
        Chess.Game storage game = games[gameId];
        Chess.Player storage currentPlayer = game.board.players[msg.sender];
        Chess.Player storage otherPlayer = game.board.players[game.board.playerSides[uint(Chess.getOtherSide(currentPlayer.side))]];
        Chess.BoardSquare storage selectedSquare = game.board.squares[prevRankPos][prevFilePos];
        Chess.BoardSquare storage squareToMoveTo = game.board.squares[newRankPos][newFilePos];

        require(game.started, "Game does not exist.");
        require(currentPlayer.side != Chess.PlayerSide.None, "User is not a part of this game.");
        require(!game.ended, "Game is done.");
        require(currentPlayer.side == game.currentTurn, "Not this players turn!");
        require(selectedSquare.isOccupied, "No piece found here");
        require(prevRankPos != newRankPos || prevFilePos != newFilePos, "No move was made");
        require(selectedSquare.piece.side == currentPlayer.side, "Piece is not owned by player");

        Chess.validateMove(prevRankPos, prevFilePos, newRankPos, newFilePos, selectedSquare.piece, game.board);

        bool pieceWasCaptured = updatePieceLocations(game, selectedSquare, squareToMoveTo);
        updateEndgameInfo(game, newRankPos, newFilePos, currentPlayer, otherPlayer, squareToMoveTo);

        string memory moveHistoryEntry = getMoveHistoryEntry(prevRankPos, prevFilePos, newRankPos, newFilePos, uint(squareToMoveTo.piece.pieceType), pieceWasCaptured);

        game.moveHistory = game.moveCount > 0 ? StringUtils.strConcat(game.moveHistory, ",", moveHistoryEntry) : moveHistoryEntry;

        game.moveCount++;

        emit MovePiece(gameId, msg.sender, game.moveHistory);

        return moveHistoryEntry;
    }

    function updatePieceLocations(Chess.Game storage game, Chess.BoardSquare storage selectedSquare, Chess.BoardSquare storage squareToMoveTo) internal returns(bool) {
        bool pieceWasCaptured = false;
        // If a piece was eliminated, add it to the capturedPieces array
        if(squareToMoveTo.isOccupied) {
            game.board.capturedPieces.push(Chess.Piece({pieceType: squareToMoveTo.piece.pieceType, side: squareToMoveTo.piece.side, hasMadeInitialMove: squareToMoveTo.piece.hasMadeInitialMove}));
            pieceWasCaptured = true;
        }

        // Remove piece from previous location...
        selectedSquare.isOccupied = false;
        squareToMoveTo.piece.pieceType = Chess.PieceType.None;
        squareToMoveTo.piece.side = Chess.PlayerSide.None;
        squareToMoveTo.piece.hasMadeInitialMove = false;

        // ...and move it to new square
        squareToMoveTo.isOccupied = true;
        squareToMoveTo.piece.pieceType = selectedSquare.piece.pieceType;
        squareToMoveTo.piece.side = selectedSquare.piece.side;
        squareToMoveTo.piece.hasMadeInitialMove = true;

        return pieceWasCaptured;
    }

    function updateEndgameInfo(Chess.Game storage game, uint newRankPos, uint newFilePos, Chess.Player storage currentPlayer, Chess.Player storage otherPlayer, Chess.BoardSquare storage squareToMoveTo) internal {
        // If this move does not take the player's king out of check, then revert this move
        if(game.inCheck == currentPlayer.side) {
            require(!Chess.positionIsThreatened(currentPlayer.kingRankPos, currentPlayer.kingFilePos, game.board, currentPlayer.side), "Player is in check. Player must protect king");
            game.inCheck = Chess.PlayerSide.None;
        }

        // Check if the game is done
        (bool inCheck, bool checkMated) = Chess.checkKingState(otherPlayer.kingRankPos, otherPlayer.kingFilePos, game, otherPlayer);

        if(inCheck) {
            game.inCheck = otherPlayer.side;
        }

        if(squareToMoveTo.piece.pieceType == Chess.PieceType.King) {
            currentPlayer.kingRankPos = newRankPos;
            currentPlayer.kingFilePos = newFilePos;
        }

        if(checkMated) {
            game.ended = true;
            game.winner = msg.sender;

            PlayerProfile storage cp = players[msg.sender];

            for(uint i = 0; i < cp.activeGames.length; i++) {
                if(cp.activeGames[i] == game.gameId) {
                    if(cp.activeGames.length > 1) {
                        cp.activeGames[i] = cp.activeGames[cp.activeGames.length - 1];
                    }
                    cp.activeGames.pop();
                }
            }
            cp.completedGames.push(game.gameId);
            cp.wins++;

            PlayerProfile storage op = players[game.board.playerSides[uint(Chess.getOtherSide(currentPlayer.side))]];

            for(uint i = 0; i < op.activeGames.length; i++) {
                if(op.activeGames[i] == game.gameId) {
                    if(op.activeGames.length > 1) {
                        op.activeGames[i] = op.activeGames[op.activeGames.length - 1];
                    }
                    op.activeGames.pop();
                }
            }
            op.completedGames.push(game.gameId);
            op.losses++;
        } else {
            game.currentTurn = otherPlayer.side;
        }
    }

    function getBasicInfoForGameByGameId(uint gameIdToSearchWith) public view returns(uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, Chess.PlayerSide currentTurn, bool started) {
        require(gameIdToSearchWith <= gameCount, "Game does not exist");
        require(games[gameIdToSearchWith].board.players[msg.sender].side != Chess.PlayerSide.None, "User is not a part of this game.");

        Chess.Game storage game = games[gameIdToSearchWith];

        gameId = gameIdToSearchWith;
        moveHistory = game.moveHistory;
        whiteAddress = game.board.playerSides[uint(Chess.PlayerSide.White)];
        blackAddress = game.board.playerSides[uint(Chess.PlayerSide.Black)];
        currentTurn = game.currentTurn;
        started = game.started;
    }

    function getEndgameInfoForGameByGameId(uint gameIdToSearchWith) public view returns(Chess.PlayerSide inCheck, bool ended, address winner, uint moveCount) {
        require(gameIdToSearchWith <= gameCount, "Game does not exist");
        require(games[gameIdToSearchWith].board.players[msg.sender].side != Chess.PlayerSide.None, "User is not a part of this game.");

        Chess.Game storage game = games[gameIdToSearchWith];

        inCheck = game.inCheck;
        ended = game.ended;
        winner = game.winner;
        moveCount = game.moveCount;
    }

    function getBasicInfoForGameByOpponentAddress(address opponentAddressToSearchWith) public view returns(uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, Chess.PlayerSide currentTurn, bool started) {
        uint[] storage activeGames = players[msg.sender].activeGames;

        for(uint i = 0; i < activeGames.length; i++) {
            if(games[activeGames[i]].board.players[opponentAddressToSearchWith].side != Chess.PlayerSide.None) {
                Chess.Game storage game = games[activeGames[i]];

                gameId = activeGames[i];
                moveHistory = game.moveHistory;
                whiteAddress = game.board.playerSides[uint(Chess.PlayerSide.White)];
                blackAddress = game.board.playerSides[uint(Chess.PlayerSide.Black)];
                currentTurn = game.currentTurn;
                started = game.started;

                break;
            }
        }
    }

    function getEndgameInfoForGameByOpponentAddress(address opponentAddressToSearchWith) public view returns(Chess.PlayerSide inCheck, bool ended, address winner, uint moveCount) {
        uint[] storage activeGames = players[msg.sender].activeGames;

        for(uint i = 0; i < activeGames.length; i++) {
            if(games[activeGames[i]].board.players[opponentAddressToSearchWith].side != Chess.PlayerSide.None) {
                require(games[activeGames[i]].board.players[msg.sender].side != Chess.PlayerSide.None, "User is not a part of this game.");

                Chess.Game storage game = games[activeGames[i]];

                inCheck = game.inCheck;
                ended = game.ended;
                winner = game.winner;
                moveCount = game.moveCount;

                break;
            }
        }
    }
    
    function getActiveGames() public view returns(address[] memory opponentAddresses, uint[] memory gameIds) {
        uint[] storage activeGames = players[msg.sender].activeGames;

        opponentAddresses = new address[](activeGames.length);
        gameIds = new uint[](activeGames.length);
        
        for(uint i = 0; i < activeGames.length; i++) {
            Chess.Game storage game = games[activeGames[i]];

            opponentAddresses[i] = game.board.playerSides[uint(Chess.getOtherSide(game.board.players[msg.sender].side))];
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

    function getUsersSearchingForGame() public view returns(address[] memory) {
        return searchingForNewGame;
    }

    function getPlayerProfile() public view returns(uint[] memory activeGames, uint[] memory completedGames, uint wins, uint losses) {
        PlayerProfile storage profile = players[msg.sender];
        activeGames = profile.activeGames;
        completedGames = profile.completedGames;
        wins = profile.wins;
        losses = profile.losses;
    }
}
