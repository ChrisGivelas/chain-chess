pragma solidity ^0.6.0;

import "./ChessGameBase.sol";

contract StandardGame is ChessGameBase {
    uint maxGamesPerUser;
    uint gameCount;

    constructor(uint maxGames) public {
        maxGamesPerUser = maxGames;
        gameCount = 0;
    }

    struct PlayerProfile {
        uint[] activeGames;
        uint[] completedGames;
        uint wins;
        uint losses;
    }

    mapping(uint => Game) games;
    mapping(address => PlayerProfile) players;

    // Using a mapping to keep track of which addresses are stored at which index in *searchingForNewGame* so that we can efficently fetch the most recent
    // users looking for a game in *searchingForNewGame*
    address[] searchingForNewGame;
    mapping(address => uint) public searchingForNewGameIndex;

    modifier maxGamesNotReached(address playerAddress) {
        require(players[playerAddress].activeGames.length < maxGamesPerUser, "User already has the maximum number of games started");
        _;
    }

    function declareSearchingForGame() public maxGamesNotReached(msg.sender) returns(bool) {
        require(searchingForNewGameIndex[msg.sender] == 0, "User already searching for new game");

        searchingForNewGameIndex[msg.sender] = searchingForNewGame.length + 1;
        searchingForNewGame.push(msg.sender);

        return true;
    }

    function acceptGame(address otherPlayer) public maxGamesNotReached(msg.sender) returns(bool) {
        require(searchingForNewGameIndex[otherPlayer] != 0, "Game does not exist");
        require(msg.sender != otherPlayer, "Two different players are required to start a new game");
        
        Game storage newGame = games[gameCount];

        initializeGame(gameCount, msg.sender, otherPlayer, newGame);
        
        players[msg.sender].activeGames.push(newGame.gameId);
        players[otherPlayer].activeGames.push(newGame.gameId);

        gameCount++;

        stopSearchingForGame(otherPlayer);
        if(searchingForNewGameIndex[msg.sender] != 0) {
            stopSearchingForGame(msg.sender);
        }
    }

    function stopSearchingForGame(address playerAddress) internal {
        uint realIndex = searchingForNewGameIndex[playerAddress] - 1;
        uint lastIndex = searchingForNewGame.length - 1;

        if(realIndex != lastIndex) {
            searchingForNewGame[realIndex] = searchingForNewGame[lastIndex];
        }

        searchingForNewGame.pop();
        searchingForNewGameIndex[playerAddress] = 0;
    }

    function initializeGame(uint gameId, address player1Address, address player2Address, Game storage newGame) internal {
        Board storage board = newGame.board;
        board.playerSides[uint8(PlayerSide.White)] = player1Address;
        board.playerSides[uint8(PlayerSide.Black)] = player2Address;

        //First coordinate represents 1 - 8 ranks (rows), second represents a - h files (columns)
        for(uint8 rank_iter = 0; rank_iter <= 7; rank_iter++) {
            for(uint8 file_iter = 0; file_iter <= 7; file_iter++) {
                if(defaultRankOwnership[rank_iter] != PlayerSide.None) {
                    board.squares[rank_iter][file_iter].isOccupied = true;
                    board.squares[rank_iter][file_iter].piece.owner = defaultRankOwnership[rank_iter] == PlayerSide.White ? player1Address : player2Address;
                    board.squares[rank_iter][file_iter].piece.pieceType = default2dPieceLayout[rank_iter][file_iter];
                    board.squares[rank_iter][file_iter].piece.side = defaultRankOwnership[rank_iter];
                    board.squares[rank_iter][file_iter].piece.hasMadeInitialMove = false;

                    if(board.squares[rank_iter][file_iter].piece.pieceType == PieceType.King) {
                        Player storage currentPlayer = newGame.board.players[newGame.board.playerSides[uint8(defaultRankOwnership[rank_iter])]];
                        currentPlayer.side = defaultRankOwnership[rank_iter];
                        currentPlayer.kingRankPos = rank_iter;
                        currentPlayer.kingFilePos = file_iter;
                    }
                }
            }
        }

        newGame.gameId = gameId;
        newGame.currentTurn = PlayerSide.White;
        newGame.started = true;
        newGame.ended = false;
        newGame.winner = address(0);
    }

    function movePiece(uint gameId, uint8 prevRankPos, uint8 prevFilePos, uint8 newRankPos, uint8 newFilePos) public returns (string memory) {
        require(games[gameId].started, "Game does not exist.");
        require(!games[gameId].ended, "Game is done.");
        require(games[gameId].board.players[msg.sender].side != PlayerSide.None, "User is not a part of this game.");

        Game storage game = games[gameId];
        Player storage currentPlayer = game.board.players[msg.sender];
        Player storage otherPlayer = game.board.players[game.board.playerSides[uint8(getOtherSide(currentPlayer.side))]];
        BoardSquare storage selectedSquare = game.board.squares[prevRankPos][prevFilePos];
        BoardSquare storage squareToMoveTo = game.board.squares[newRankPos][newFilePos];

        require(selectedSquare.isOccupied, "No piece found at this location");
        require(selectedSquare.piece.owner == msg.sender, "Piece is not owned by sender");
        require(isValidMove(prevRankPos, prevFilePos, newRankPos, newFilePos, selectedSquare.piece, game.board), "Invalid move");

        bool pieceWasCaptured = false;
        // If a piece was eliminated, add it to the capturedPieces array
        if(squareToMoveTo.isOccupied) {
            game.board.capturedPieces.push(clonePiece(squareToMoveTo.piece));
            pieceWasCaptured = true;
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
            (bool inCheck,) = checkKingState(game, currentPlayer);

            if(inCheck) {
                revert("Player is in check. Must protect king");
            }
        } else {
            game.board.inCheck = PlayerSide.None;
        }

        // Check if the game is done
        (bool inCheck, bool checkMated) = checkKingState(game, otherPlayer);

        if(checkMated) {
            game.ended = true;
            game.winner = msg.sender;
        } else {
            if(inCheck) {
                game.board.inCheck = otherPlayer.side;
            }

            if(selectedSquare.piece.pieceType == PieceType.King) {
                currentPlayer.kingRankPos = newRankPos;
                currentPlayer.kingFilePos = newFilePos;
            }

            game.currentTurn = otherPlayer.side;
        }

        string memory moveHistoryEntry = getMoveHistoryEntry(prevRankPos, prevFilePos, newRankPos, newFilePos, uint8(squareToMoveTo.piece.pieceType), pieceWasCaptured, game.ended);

        game.moveHistory = strConcat(game.moveHistory, moveHistoryEntry);

        return moveHistoryEntry;
    }

    function getOtherSide(PlayerSide playerSide) pure internal returns(PlayerSide) {
        if(playerSide == PlayerSide.White) return PlayerSide.Black;
        else if(playerSide == PlayerSide.Black) return PlayerSide.Black;
        else return PlayerSide.None;
    }

    function getGame(uint gameId) public view returns(string memory, PlayerSide , bool, bool, address, PlayerSide, address, PlayerSide, address) {
        Game storage game = games[gameId];

        return (
            game.moveHistory,
            game.currentTurn,
            game.started,
            game.ended,
            game.board.playerSides[uint8(PlayerSide.White)],
            PlayerSide.White,
            game.board.playerSides[uint8(PlayerSide.Black)],
            PlayerSide.Black,
            game.winner
        );
    }

    function getactiveGames() public view returns(address[] memory opponentAddresses, uint[] memory gameIds) {
        uint[] storage activeGames = players[msg.sender].activeGames;

        require(activeGames.length > 0, "User has no active games");
        
        for(uint i = 0; i < activeGames.length; i++) {
            Game storage game = games[activeGames[i]];

            opponentAddresses[i] = game.board.playerSides[uint8(getOtherSide(game.board.players[msg.sender].side))];
            gameIds[i] = game.gameId;
        }
    }

    function getUsersSearchingForGame(uint num) public view returns(address[] memory searchingUsers) {
        uint lastIndex = searchingForNewGame.length - 1;
        uint lowerLimit = num > lastIndex ? 0 : lastIndex - num;
        for(uint i = lastIndex; i > lowerLimit; i--) {
            searchingUsers[i] = (searchingForNewGame[i]);
        }
    }
}
