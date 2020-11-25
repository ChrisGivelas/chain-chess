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

        (uint gameId, bool started, string memory moveHistory, address player1Address, address player2Address, string memory errMsg2) = player1.getGameByGameId(newGameId);

        Assert.equal(errMsg2, "", "Error message shouldn't exist");
        Assert.equal(newGameId, gameId, "Game ids don't match");
        Assert.isTrue(started, "Game should have started");
        Assert.equal(player1Address, address(player1), "Player 1 address incorrect");
        Assert.equal(player2Address, address(player2), "Player 2 address incorrect");

        testGameId1 = gameId;
    }

    function testMovePiece_initialPawnMove_isValid() public {
        (string memory move, string memory errMsg) = player1.movePiece(testGameId1, 1, 4, 3, 4);

        Assert.equal(errMsg, "", "Error message shouldn't exist");
        Assert.equal(move, "pe2e4", "Move entry is incorrect");
    }

    function testMovePiece_captureWithPawn_isValid() public {
        (string memory move1, string memory errMsg1) = player2.movePiece(testGameId1, 6, 3, 4, 3);

        Assert.equal(errMsg1, "", "Error message 1 shouldn't exist");
        Assert.equal(move1, "pd7d5", "Move entry is incorrect");

        (string memory move2, string memory errMsg2) = player1.movePiece(testGameId1, 3, 4, 4, 3);

        Assert.equal(errMsg2, "", "Error message 2 shouldn't exist");
        Assert.equal(move2, "pe4xd5", "Move entry is incorrect");
    }
}