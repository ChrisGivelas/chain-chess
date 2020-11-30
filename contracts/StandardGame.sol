pragma solidity >=0.6.0 <0.8.0;

import "./Chess.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Standard Chess Game
/// @author Christopher Givelas
contract StandardGame is Ownable {
    bool public stopped = false;

    modifier stopInEmergency {
        require (!stopped);
        _;
    }

    function stop() public onlyOwner {
        stopped = false;
    }

    function start() public onlyOwner {
        stopped = true;
    }

    address[] public searchingForNewGame;
    uint gameCount;
    mapping(uint => Chess.Game) games;
    mapping(address => PlayerProfile) players;

    event PieceMove(uint indexed gameId, address indexed playerMakingMove, address indexed otherPlayer, string moveHistoryEntry, Chess.PlayerSide nextTurn);
    event GameStart(uint indexed gameId, address indexed address1, address indexed address2);
    event Checkmate(uint indexed gameId, address indexed winner, address indexed loser);

    struct PlayerProfile {
        uint[] activeGames;
        uint[] completedGames;
        uint wins;
        uint losses;
    }

    /// @notice initialize Standard Game
    constructor() public {
        gameCount = 0;
    }

    /// @notice Start searching for game
    /// @return bool - whether the user has successfully started searching for a game
    function declareSearchingForGame() public stopInEmergency returns(bool) {
        require(!userIsSearching(msg.sender), "User already searching for new game");

        searchingForNewGame.push(msg.sender);

        return true;
    }

    /// @notice Check if a user is currently searching for a game
    /// @param playerAddress the address to check for
    /// @return bool - wheather the player is searching
    function userIsSearching(address playerAddress) public view stopInEmergency returns(bool) {
        for(uint i = 0; i < searchingForNewGame.length; i++) {
            if(searchingForNewGame[i] == playerAddress) {
                return true;
            }
        }

        return false;
    }

    /// @notice Check if `msg.sender` is already playing `otherPlayer`
    /// @param otherPlayer the address of the other player
    /// @return bool - wheather the two players are already playing a game
    function alreadyPlaying(address otherPlayer) internal view returns (bool) {
        uint[] storage activeGames = players[msg.sender].activeGames;
        
        for(uint i = 0; i < activeGames.length; i++) {
            Chess.Game storage game = games[activeGames[i]];
            if(otherPlayer == game.board.playerSides[uint(Chess.getOtherSide(game.board.players[msg.sender].side))]) {
                return true;
            }
        }

        return false;
    }

    /// @notice Accept game with `otherPlayer`
    /// @param otherPlayer the other player to start a game with
    /// @return uint - the game id of the new game created
    function acceptGame(address otherPlayer) public stopInEmergency returns(uint) {
        require(msg.sender != otherPlayer, "Two different players are required to start a new game");
        require(userIsSearching(otherPlayer), "Game does not exist");
        require(!alreadyPlaying(otherPlayer), "Users are already playing");
        
        Chess.Game storage newGame = games[gameCount];

        initializeGame(msg.sender, otherPlayer, newGame);
        
        players[msg.sender].activeGames.push(newGame.gameId);
        players[otherPlayer].activeGames.push(newGame.gameId);

        gameCount++;

        stopSearchingForGame(otherPlayer);
        if(userIsSearching(msg.sender)) {
            stopSearchingForGame(msg.sender);
        }

        emit GameStart(newGame.gameId, msg.sender, otherPlayer);

        return newGame.gameId;
    }

    /// @notice Stop searching for a game for a given user
    /// @param playerAddress the user to stop searching for
    function stopSearchingForGame(address playerAddress) internal {
        for(uint i = 0; i < searchingForNewGame.length; i++) {
            if(searchingForNewGame[i] == playerAddress) {
                searchingForNewGame[i] = searchingForNewGame[searchingForNewGame.length - 1];
                searchingForNewGame.pop();
            }
        }
    }

    /// @notice Start a new game
    /// @param player1Address the address of the first player
    /// @param player2Address the address of the second player
    /// @param newGame the game to initialize
    function initializeGame(address player1Address, address player2Address, Chess.Game storage newGame) internal {
        Chess.Board storage board = newGame.board;
        board.playerSides[uint(Chess.PlayerSide.White)] = player1Address;
        board.playerSides[uint(Chess.PlayerSide.Black)] = player2Address;

        board.players[player1Address].side = Chess.PlayerSide.White;
        board.players[player1Address].kingRank = 0;
        board.players[player1Address].kingFile = 4;

        board.players[player2Address].side = Chess.PlayerSide.Black;
        board.players[player2Address].kingRank = 7;
        board.players[player2Address].kingFile = 4;

        for(uint rank_iter = 0; rank_iter <= 7; rank_iter++) {
            for(uint file_iter = 0; file_iter <= 7; file_iter++) {
                setInitialPositionForPiece(rank_iter, file_iter, board.squares[rank_iter][file_iter]);
            }
        }

        newGame.gameId = gameCount++;
        newGame.currentTurn = Chess.PlayerSide.White;
        newGame.started = true;
        newGame.ended = false;
        newGame.winner = address(0);
        newGame.moveHistory = "";
        newGame.moveCount = 0;
    }

    /// @notice Setup square for the initial board state
    /// @param rank the rank of the square we are initializing
    /// @param file the file of the square we are initializing
    /// @param square the square to initialize
    function setInitialPositionForPiece(uint rank, uint file, Chess.BoardSquare storage square) internal {
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

    /// @notice Move a piece for a given game
    /// @param gameId the id of the game that this move is to be played in
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @return string - the valid piece move in algebraic notation (https://en.wikipedia.org/wiki/Algebraic_notation_(chess))
    function movePiece(uint gameId, uint prevRank, uint prevFile, uint newRank, uint newFile) public stopInEmergency returns (string memory) {
        Chess.Game storage game = games[gameId];
        Chess.Player storage currentPlayer = game.board.players[msg.sender];
        Chess.PlayerSide otherSide = Chess.getOtherSide(currentPlayer.side);
        Chess.Player storage otherPlayer = game.board.players[game.board.playerSides[uint(otherSide)]];
        Chess.BoardSquare storage selectedSquare = game.board.squares[prevRank][prevFile];
        Chess.BoardSquare storage squareToMoveTo = game.board.squares[newRank][newFile];

        require(game.started, "Game does not exist.");
        require(currentPlayer.side != Chess.PlayerSide.None, "User is not a part of this game.");
        require(!game.ended, "Game is done.");
        require(currentPlayer.side == game.currentTurn, "Not this players turn!");
        require(selectedSquare.isOccupied, "No piece found here");
        require(prevRank != newRank || prevFile != newFile, "No move was made");
        require(selectedSquare.piece.side == currentPlayer.side, "Piece is not owned by player");

        Chess.validateMove(prevRank, prevFile, newRank, newFile, selectedSquare.piece, game.board);

        bool pieceWasCaptured = updatePieceLocations(game, selectedSquare, squareToMoveTo);

        if(squareToMoveTo.piece.pieceType == Chess.PieceType.King) {
            currentPlayer.kingRank = newRank;
            currentPlayer.kingFile = newFile;
        }

        updateEndgameInfo(game, currentPlayer, otherPlayer);

        string memory moveHistoryEntry = getMoveHistoryEntry(prevRank, prevFile, newRank, newFile, uint(squareToMoveTo.piece.pieceType), pieceWasCaptured);

        game.moveHistory = game.moveCount > 0 ? StringUtils.strConcat(game.moveHistory, ",", moveHistoryEntry) : moveHistoryEntry;

        game.moveCount++;

        emit PieceMove(gameId, msg.sender, game.board.playerSides[uint(otherSide)], moveHistoryEntry, otherSide);

        return moveHistoryEntry;
    }

    /// @notice Update piece locations after move. Remove any captured piece
    /// @param game the game to update
    /// @param selectedSquare the square containing the piece to move
    /// @param squareToMoveTo the square to move the piece to
    /// @return bool - returns true if a piece was captured
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

    /// @notice update all of the end game info for a game
    /// @param game the game to update
    /// @param currentPlayer the current player making a move
    /// @param otherPlayer the other player for the given game
    function updateEndgameInfo(Chess.Game storage game, Chess.Player storage currentPlayer, Chess.Player storage otherPlayer) internal {
        // If this move does not take the player's king out of check, then revert this move
        if(game.inCheck == currentPlayer.side) {
            require(!Chess.positionIsThreatened(currentPlayer.kingRank, currentPlayer.kingFile, game.board, currentPlayer.side), "Player is in check. Player must protect king");
            game.inCheck = Chess.PlayerSide.None;
        }

        // Check if the game is done
        (bool inCheck, bool checkMated) = Chess.checkKingState(otherPlayer.kingRank, otherPlayer.kingFile, game.board, otherPlayer.side);

        if(inCheck) {
            game.inCheck = otherPlayer.side;
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

            emit Checkmate(game.gameId, msg.sender, game.board.playerSides[uint(Chess.getOtherSide(currentPlayer.side))]);
        } else {
            game.currentTurn = otherPlayer.side;
        }
    }

    /// @notice get all basic info for a game using gameId
    /// @param gameIdToSearchWith the game id to search with
    /// @return gameId - the id of the game found
    /// @return moveHistory - the move history of the returned game
    /// @return whiteAddress - the address of white in the returned game
    /// @return blackAddress - the address of black in the returned game
    /// @return currentTurn - the current turn in the returned game
    /// @return started - whether the game has actually started
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

    /// @notice get all end game info for a game using gameId
    /// @param gameIdToSearchWith the game id to search with
    /// @return inCheck - the side of the player in check
    /// @return ended - whether the game is completed
    /// @return winner - the address of the winner
    /// @return moveCount - the number of moves that have been made in the game
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

    /// @notice get all endgame info for a game using the opponent's address
    /// @param opponentAddressToSearchWith the opponent address to search with
    /// @return inCheck - the side of the player in check
    /// @return ended - whether the game is completed
    /// @return winner - the address of the winner
    /// @return moveCount - the number of moves that have been made in the game
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
    
    /// @notice Get active games for a player
    /// @return opponentAddresses - the opponents for all active games of this user
    /// @return gameIds - the game ids for all active games of this user
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

    /// @notice Convert move information to string format
    /// @param prevRank previous rank of the piece to move
    /// @param prevFile previous file of the piece to move
    /// @param newRank new rank to move this piece to
    /// @param newFile new file to move this piece to
    /// @param pieceEnumValue the enum index of the piece to move
    /// @param isCapture if this piece captured another piece
    /// @return string - the string representation of this move
    function getMoveHistoryEntry(uint prevRank, uint prevFile, uint newRank, uint newFile, uint pieceEnumValue, bool isCapture) internal view returns(string memory) {
        return StringUtils.strConcat(
            pieceIdMapping[pieceEnumValue],
            fileIdMapping[prevFile],
            rankIdMapping[prevRank],
            isCapture ? "x" : "",
            fileIdMapping[newFile],
            rankIdMapping[newRank]
        );
    }

    /// @notice get all currently searching users
    /// @return address[] - addresses of all searching users
    function getUsersSearchingForGame() public view returns(address[] memory) {
        return searchingForNewGame;
    }

    /// @notice get the player profile for this user
    /// @param activeGames ids of all active games for this player
    /// @param completedGames ids for all completed games for this player
    /// @param wins number of wins for this player
    /// @param losses number of losses for this player
    function getPlayerProfile() public view returns(uint[] memory activeGames, uint[] memory completedGames, uint wins, uint losses) {
        PlayerProfile storage profile = players[msg.sender];
        activeGames = profile.activeGames;
        completedGames = profile.completedGames;
        wins = profile.wins;
        losses = profile.losses;
    }
}
