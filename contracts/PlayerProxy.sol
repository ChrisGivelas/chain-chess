pragma solidity >=0.6.0 <0.8.0;

import "./StandardGame.sol";
import "./Chess.sol";

/// @title A utility contract for unit testing. Simulates a player making moves
/// @author Christopher Givelas
contract PlayerProxy {
    address standardGameAddress;

    constructor(address _standardGameAddress) public {
        standardGameAddress = _standardGameAddress;
    }

    function declareSearchingForGame() public returns(bool returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).declareSearchingForGame() returns (bool isSearching) {
            returnVal = isSearching;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }

    function acceptGame(address opponentAddress) public returns (uint returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).acceptGame(opponentAddress) returns(uint gameId) {
            returnVal = gameId;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }

    function movePiece(uint gameId, uint prevRankPos, uint prevFilePos, uint newRankPos, uint newFilePos) public returns (string memory returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).movePiece(gameId, prevRankPos, prevFilePos, newRankPos, newFilePos) returns(string memory moveHistoryEntry) {
            returnVal = moveHistoryEntry;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }

    function getBasicInfoForGameByGameId(uint gameIdToSearchFor) public view returns (uint gameId, string memory moveHistory, address whiteAddress, address blackAddress, uint currentTurn, bool started, string memory errMsg) {
        try StandardGame(standardGameAddress).getBasicInfoForGameByGameId(gameIdToSearchFor) returns (uint game_gameId, string memory game_moveHistory, address game_whiteAddress, address game_blackAddress, Chess.PlayerSide game_currentTurn, bool game_started) {
            gameId = game_gameId;
            moveHistory = game_moveHistory;
            whiteAddress = game_whiteAddress;
            blackAddress = game_blackAddress;
            currentTurn = uint(game_currentTurn);
            started = game_started;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }

    function getEndgameInfoForGameByGameId(uint gameIdToSearchFor) public view returns (uint inCheckSide, bool ended, address winner, uint moveCount, string memory errMsg) {
        try StandardGame(standardGameAddress).getEndgameInfoForGameByGameId(gameIdToSearchFor) returns (Chess.PlayerSide game_inCheck, bool game_ended, address game_winner, uint game_moveCount) {
            inCheckSide = uint(game_inCheck);
            ended = game_ended;
            winner = game_winner;
            moveCount = game_moveCount;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }

    function getActiveGames() public view returns (address[] memory opponentAddresses, uint[] memory gameIds, string memory errMsg) {
        try StandardGame(standardGameAddress).getActiveGames() returns (address[] memory addrs, uint[] memory ids) {
            opponentAddresses = addrs;
            gameIds = ids;
        } catch Error(string memory reason) {
            errMsg = reason;
        }
    }
}