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


    function beforeAll() public {
        player1 = new PlayerProxy(address(standardGame));
        player2 = new PlayerProxy(address(standardGame));
        player3 = new PlayerProxy(address(standardGame));
        player4 = new PlayerProxy(address(standardGame));
        player5 = new PlayerProxy(address(standardGame));
    }

    function testDeclareSearchingForGame() public {
        (bool returnVal, string memory errMsg) = player1.declareSearchingForGame();

        Assert.isTrue(returnVal, "Should return true");
    }

    function testGetUsersSearchingForGame() public {
        player2.declareSearchingForGame();
        player3.declareSearchingForGame();
        player4.declareSearchingForGame();

        (address[] memory returnVal, string memory errMsg) = player5.getUsersSearchingForGame();

        Assert.equal(returnVal.length, 4, "Array size should be 4");
        Assert.equal(returnVal[0], address(player1), "Incorrect player in position 0");
        Assert.equal(returnVal[1], address(player2), "Incorrect player in position 0");
        Assert.equal(returnVal[2], address(player3), "Incorrect player in position 0");
        Assert.equal(returnVal[3], address(player4), "Incorrect player in position 0");
    }
}