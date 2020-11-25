pragma solidity ^0.6.0;

import "./StandardGame.sol";
import "./StringUtils.sol";

contract PlayerProxy {
    address standardGameAddress;

    constructor(address _standardGameAddress) public {
        standardGameAddress = _standardGameAddress;
    }

    function declareSearchingForGame() public returns(bool returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).declareSearchingForGame() returns (bool isSearching) {
            returnVal = isSearching;
            if(!isSearching) {
                errMsg = "Failure: false";
            }
        } catch Error(string memory reason) {
            errMsg = StringUtils.strConcat("Failure - ", reason);
        }
    }

    function acceptGame(address opponentAddress) public returns (uint returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).acceptGame(opponentAddress) returns(uint gameId) {
            returnVal = gameId;
        } catch Error(string memory reason) {
            errMsg = StringUtils.strConcat("Failure: ", reason);
        }
    }

    function movePiece(uint gameId, uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) public returns (string memory returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).movePiece(gameId, prevRankPos, prevFilePos, newRankPos, newFilePos) returns(string memory moveHistoryEntry) {
            returnVal = moveHistoryEntry;
        } catch Error(string memory reason) {
            errMsg = StringUtils.strConcat("Failure: ", reason);
        }
    }

    function getGameByGameId(uint gameIdToSearchFor) public view returns (uint id, bool started, string memory moveHistory, address player1Address, address player2Address, string memory errMsg) {
        try StandardGame(standardGameAddress).getGameByGameId(gameIdToSearchFor) returns (uint gameId, string memory game_moveHistory, StandardGame.PlayerSide game_currentTurn, bool game_started, bool game_ended, address game_player1Address, StandardGame.PlayerSide game_player1Side, address game_player2Address, StandardGame.PlayerSide game_player2Side, address game_winner) {
            id = gameId;
            started = game_started;
            moveHistory = game_moveHistory;
            player1Address = game_player1Address;
            player2Address = game_player2Address;
        } catch Error(string memory reason) {
            errMsg = StringUtils.strConcat("Failure: ", reason);
        }
    }
}