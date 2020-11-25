pragma solidity ^0.6.0;

import "./BaseGame.sol";

contract StandardGame is BaseGame {
    address[] public searchingForNewGame;

    constructor(uint maxGames) public BaseGame(maxGames) {}

    modifier maxGamesNotReached(address playerAddress) {
        require(players[playerAddress].activeGames.length < maxGamesPerUser, "User already has the maximum number of games started");
        _;
    }

    function declareSearchingForGame() public maxGamesNotReached(msg.sender) returns(bool) {
        require(!userIsSearching(msg.sender), "User already searching for new game");

        searchingForNewGame.push(msg.sender);

        return true;
    }

    function userIsSearching(address playerAddress) internal view returns(bool) {
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
        
        Game storage newGame = games[gameCount];

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

    function initializeGame(uint gameId, address player1Address, address player2Address, Game storage newGame) internal {
        Board storage board = newGame.board;
        board.playerSides[uint(PlayerSide.White)] = player1Address;
        board.playerSides[uint(PlayerSide.Black)] = player2Address;

        board.players[player1Address].side = PlayerSide.White;
        board.players[player1Address].kingRankPos = 0;
        board.players[player1Address].kingFilePos = 4;

        board.players[player2Address].side = PlayerSide.Black;
        board.players[player2Address].kingRankPos = 7;
        board.players[player2Address].kingFilePos = 4;

        for(uint i = 0; i <= 7; i++) {
            for(uint j = 0; j <= 7; j++) {
                setInitialPositionForPiece(i, j, board.squares[i][j]);
            }
        }

        newGame.gameId = gameId;
        newGame.currentTurn = PlayerSide.White;
        newGame.started = true;
        newGame.ended = false;
        newGame.winner = address(0);
        newGame.moveHistory = "";
    }

    function setInitialPositionForPiece(uint rank, uint file, BoardSquare storage square) internal returns (Piece memory) {
        Piece memory temp;

        if(rank == 0) {
            if(file == 0) temp = Piece(PieceType.Rook, PlayerSide.White, false);
            if(file == 1) temp = Piece(PieceType.Knight, PlayerSide.White, false);
            if(file == 2) temp = Piece(PieceType.Bishop, PlayerSide.White, false);
            if(file == 3) temp = Piece(PieceType.Queen, PlayerSide.White, false);
            if(file == 4) temp = Piece(PieceType.King, PlayerSide.White, false);
            if(file == 5) temp = Piece(PieceType.Bishop, PlayerSide.White, false);
            if(file == 6) temp = Piece(PieceType.Knight, PlayerSide.White, false);
            if(file == 7) temp = Piece(PieceType.Rook, PlayerSide.White, false);
        } else if(rank == 1) {
            temp = Piece(PieceType.Pawn, PlayerSide.White, false);
        } else if(rank == 6) {
            temp = Piece(PieceType.Pawn, PlayerSide.Black, false);
        } else if(rank == 7) {
            if(file == 0) temp = Piece(PieceType.Rook, PlayerSide.Black, false);
            if(file == 1) temp = Piece(PieceType.Knight, PlayerSide.Black, false);
            if(file == 2) temp = Piece(PieceType.Bishop, PlayerSide.Black, false);
            if(file == 3) temp = Piece(PieceType.Queen, PlayerSide.Black, false);
            if(file == 4) temp = Piece(PieceType.King, PlayerSide.Black, false);
            if(file == 5) temp = Piece(PieceType.Bishop, PlayerSide.Black, false);
            if(file == 6) temp = Piece(PieceType.Knight, PlayerSide.Black, false);
            if(file == 7) temp = Piece(PieceType.Rook, PlayerSide.Black, false);
        }

        square.piece.pieceType = temp.pieceType;
        square.piece.side = temp.side;
        square.piece.hasMadeInitialMove = temp.hasMadeInitialMove;

        if(rank == 0 || rank == 1 || rank == 6 || rank == 7) {
            square.isOccupied = true;
        }
    }

    function movePiece(uint gameId, uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) public returns (string memory) {
        require(games[gameId].started, "Game does not exist.");
        require(!games[gameId].ended, "Game is done.");
        require(games[gameId].board.players[msg.sender].side != PlayerSide.None, "User is not a part of this game.");

        Game storage game = games[gameId];
        Player storage currentPlayer = game.board.players[msg.sender];
        BoardSquare storage selectedSquare = game.board.squares[prevRankPos][prevFilePos];
        BoardSquare storage squareToMoveTo = game.board.squares[newRankPos][newFilePos];

        require(selectedSquare.isOccupied, "No piece found here");
        require(selectedSquare.piece.side == currentPlayer.side, "Piece is not owned by player");

        validateMove(prevRankPos, prevFilePos, newRankPos, newFilePos, selectedSquare.piece, game.board);

        bool pieceWasCaptured = updatePieceLocations(game, selectedSquare, squareToMoveTo);
        updateEndgameInfo(game, newRankPos, newFilePos);

        string memory moveHistoryEntry = getMoveHistoryEntry(prevRankPos, prevFilePos, newRankPos, newFilePos, uint(squareToMoveTo.piece.pieceType), pieceWasCaptured);

        game.moveHistory = StringUtils.strConcat(game.moveHistory, moveHistoryEntry);

        return moveHistoryEntry;
    }

    function updatePieceLocations(Game storage game, BoardSquare storage selectedSquare, BoardSquare storage squareToMoveTo) internal returns(bool) {
        bool pieceWasCaptured = false;
        // If a piece was eliminated, add it to the capturedPieces array
        if(squareToMoveTo.isOccupied) {
            game.board.capturedPieces.push(Piece({pieceType: squareToMoveTo.piece.pieceType, side: squareToMoveTo.piece.side, hasMadeInitialMove: squareToMoveTo.piece.hasMadeInitialMove}));
            pieceWasCaptured = true;
        }

        // Remove piece from previous location...
        selectedSquare.isOccupied = false;
        squareToMoveTo.piece.pieceType = PieceType.None;
        squareToMoveTo.piece.side = PlayerSide.None;
        squareToMoveTo.piece.hasMadeInitialMove = false;

        // ...and move it to new square
        squareToMoveTo.isOccupied = true;
        squareToMoveTo.piece.pieceType = selectedSquare.piece.pieceType;
        squareToMoveTo.piece.side = selectedSquare.piece.side;
        squareToMoveTo.piece.hasMadeInitialMove = true;

        return pieceWasCaptured;
    }

    function updateEndgameInfo(Game storage game, uint newRankPos, uint newFilePos) internal {
        Player storage currentPlayer = game.board.players[msg.sender];
        Player storage otherPlayer = game.board.players[game.board.playerSides[uint(getOtherSide(currentPlayer.side))]];
        BoardSquare storage squareToMoveTo = game.board.squares[newRankPos][newFilePos];

        // If this move does not take the player's king out of check, then revert this move
        if(game.board.inCheck == currentPlayer.side) {
            require(!positionIsThreatened(currentPlayer.kingRankPos, currentPlayer.kingFilePos, game.board, currentPlayer.side), "Player is in check. Player must protect king");
            game.board.inCheck = PlayerSide.None;
        }

        // Check if the game is done
        (bool inCheck, bool checkMated) = checkKingState(otherPlayer.kingRankPos, otherPlayer.kingFilePos, game, otherPlayer);

        if(inCheck) {
            game.board.inCheck = otherPlayer.side;
        }

        if(squareToMoveTo.piece.pieceType == PieceType.King) {
            currentPlayer.kingRankPos = newRankPos;
            currentPlayer.kingFilePos = newFilePos;
        }

        if(checkMated) {
            game.ended = true;
            game.winner = msg.sender;
        } else {
            game.currentTurn = otherPlayer.side;
        }
    }

    function getUsersSearchingForGame() public view returns(address[] memory) {
        return searchingForNewGame;
    }
}
