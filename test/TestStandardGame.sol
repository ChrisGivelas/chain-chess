pragma solidity ^0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StandardGame.sol";
import "../contracts/PlayerProxy.sol";

contract TestStandardGame {
    StandardGame standardGame = StandardGame(DeployedAddresses.StandardGame());

    PlayerProxy player1;
    PlayerProxy player2;
    PlayerProxy player3;
    PlayerProxy player4;
    PlayerProxy player5;

    uint testGameId1;

    function beforeAll() public {
        player1 = new PlayerProxy(address(standardGame));
        player2 = new PlayerProxy(address(standardGame));
        player3 = new PlayerProxy(address(standardGame));
        player4 = new PlayerProxy(address(standardGame));
        player5 = new PlayerProxy(address(standardGame));
    }

    function testDeclareSearchingForGame() public {
        (bool returnVal, string memory errMsg) = player1.declareSearchingForGame();

        Assert.equal(errMsg, "", "Error message shouldn't exist");
        Assert.isTrue(returnVal, "Should return true");
    }

    function testGetUsersSearchingForGame() public {
        player2.declareSearchingForGame();
        player3.declareSearchingForGame();
        player4.declareSearchingForGame();

        address[] memory usersSearching = standardGame.getUsersSearchingForGame();

        Assert.equal(usersSearching.length, 4, "Array size should be 4");
        Assert.equal(usersSearching[0], address(player1), "Incorrect player in position 0");
        Assert.equal(usersSearching[1], address(player2), "Incorrect player in position 1");
        Assert.equal(usersSearching[2], address(player3), "Incorrect player in position 2");
        Assert.equal(usersSearching[3], address(player4), "Incorrect player in position 3");
    }

    function testAcceptGame() public {
        (uint newGameId, string memory errMsg1) = player1.acceptGame(address(player2));

        Assert.equal(errMsg1, "", "Error message shouldn't exist");
        Assert.equal(standardGame.getUsersSearchingForGame().length, 2, "Less players should be searching now");

        (uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, uint currentTurn, bool started, string memory errMsg2) = player1.getBasicInfoForGameByGameId(newGameId);

        Assert.equal(errMsg2, "", "Error message shouldn't exist");
        Assert.isTrue(started, "Game should have started");
        Assert.equal(whiteAddress, address(player1), "Player 1 address incorrect");
        Assert.equal(blackAddress, address(player2), "Player 2 address incorrect");
        Assert.equal(currentTurn, 1, "Should be white's turn");

        testGameId1 = newGameId;
    }

    function testMovePiece_initialPawnMove_isValid() public {
        // white move pawn from e2 to e4
        (string memory move, string memory errMsg) = player1.movePiece(testGameId1, 1, 4, 3, 4);

        Assert.equal(errMsg, "", "Error message shouldn't exist");
        Assert.equal(move, "pe2e4", "Move entry is incorrect");
    }

    function testMovePiece_captureWithPawn_isValid() public {
        // black move pawn from d7 to d5
        (string memory move1, string memory errMsg1) = player2.movePiece(testGameId1, 6, 3, 4, 3);

        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "pd7d5", "Move entry is incorrect");

        // white captures on d5
        (string memory move2, string memory errMsg2) = player1.movePiece(testGameId1, 3, 4, 4, 3);

        Assert.equal(errMsg2, "", "Error message 2 shouldn't exist");
        Assert.equal(move2, "pe4xd5", "Move entry is incorrect");
    }

    function testMovePiece_initialQueenMoveAndCaptureWithQueen_isValid() public {
        // black move queen from d8 to d5
        (string memory move1, string memory errMsg1) = player2.movePiece(testGameId1, 7, 3, 4, 3);

        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "qd8xd5", "Move entry is incorrect");
    }

    function testMovePiece_outOfTurn_throwsError() public {
        // cheeky black queen wants to move again!? (from d5 to g2)
        (string memory move1, string memory errMsg1) = player2.movePiece(testGameId1, 4, 3, 1, 6);

        Assert.equal(errMsg1, "Not this players turn!", "Incorrect error message");
    }

    function testGetActiveGames() public {
        (address[] memory opponentAddresses, uint[] memory gameIds, string memory errMsg) = player1.getActiveGames();

        Assert.equal(errMsg, "", "Error message shouldn't exist");
        Assert.equal(opponentAddresses.length, 1, "Incorrect number of active games");
        Assert.equal(gameIds.length, 1, "Incorrect number of active games");
        Assert.equal(opponentAddresses[0], address(player2), "Wrong opponent address");

        (opponentAddresses, gameIds, errMsg) = player2.getActiveGames();

        Assert.equal(errMsg, "", "Error message shouldn't exist");
        Assert.equal(opponentAddresses.length, 1, "Incorrect number of active games");
        Assert.equal(gameIds.length, 1, "Incorrect number of active games");
        Assert.equal(opponentAddresses[0], address(player1), "Wrong opponent address");
    }

    function testMovePiece_queensSkipsOverOwnPiece_throwsError() public {
        // cheeky white queen wants to hop over pawn to sneak attack black queen!? (from d1 to d5)
        (string memory move1, string memory errMsg1) = player1.movePiece(testGameId1, 0, 3, 4, 3);

        Assert.equal(errMsg1, "Omnidirectional move is blocked", "Incorrect error message");
    }

    function testMovePiece_bishopPlacesKingInCheck_isValid() public {
        // White bishop places black king in check (from f1 to b5)
        (string memory move1, string memory errMsg1) = player1.movePiece(testGameId1, 0, 5, 4, 1);

        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "bf1b5", "Move entry is incorrect");

        (uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, uint currentTurn, bool started,) = player1.getBasicInfoForGameByGameId(testGameId1);
        (uint inCheckSide, bool ended, address winner, uint moveCount,) = player1.getEndgameInfoForGameByGameId(testGameId1);

        Assert.equal(moveHistory, "pe2e4,pd7d5,pe4xd5,qd8xd5,bf1b5", "Move history incorrect");
        Assert.equal(inCheckSide, 2, "Black player should be in check");
    }

    function testMovePiece_queenCapturesBishop() public {
        // White bishop is captured by Black Queen (d5 to b5)
        (string memory move1, string memory errMsg1) = player2.movePiece(testGameId1, 4, 3, 4, 1);

        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "qd5xb5", "Move entry is incorrect");
    }

    function testMovePieces_blackCheckmates() public {
        (string memory move1, string memory errMsg1) = player1.movePiece(testGameId1, 0, 3, 3, 6);
        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "qd1g4", "Move entry is incorrect");

        (string memory move2, string memory errMsg2) = player2.movePiece(testGameId1, 7, 2, 3, 6);
        Assert.equal(errMsg2, "", "Error message 2 shouldn't exist");
        Assert.equal(move2, "bc8xg4", "Move entry is incorrect");

        (string memory move3, string memory errMsg3) = player1.movePiece(testGameId1, 0, 6, 1, 4);
        Assert.equal(errMsg3, "", "Error message 3 shouldn't exist");
        Assert.equal(move3, "ng1e2", "Move entry is incorrect");

        (string memory move4, string memory errMsg4) = player2.movePiece(testGameId1, 4, 1, 1, 4); // checkmate move
        Assert.equal(errMsg4, "", "Error message 4 shouldn't exist");
        Assert.equal(move4, "qb5xe2", "Move entry is incorrect");

        (uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, uint currentTurn, bool started,) = player1.getBasicInfoForGameByGameId(testGameId1);
        (uint inCheckSide, bool ended, address winner, uint moveCount,) = player1.getEndgameInfoForGameByGameId(testGameId1);

        Assert.equal(moveHistory, "pe2e4,pd7d5,pe4xd5,qd8xd5,bf1b5,qd5xb5,qd1g4,bc8xg4,ng1e2,qb5xe2", "Move history incorrect");
        Assert.equal(inCheckSide, 1, "White player should be in check");
        Assert.isTrue(ended, "Game is done");
        Assert.equal(winner, blackAddress, "Black player should be the winner");
    }

    function testMovePieces_whiteTrysMoveAfterGameEnds_throwsError() public {
        (string memory move1, string memory errMsg1) = player1.movePiece(testGameId1, 1, 0, 3, 1);
        Assert.equal(errMsg1, "Game is done.", "Incorrect error message");
    }
}