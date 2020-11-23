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

    function getUsersSearchingForGame() public view returns (address[] memory returnVal, string memory errMsg) {
        try StandardGame(standardGameAddress).getUsersSearchingForGame() returns(address[] memory searchingUsers) {
            returnVal = searchingUsers;
        } catch Error(string memory reason) {
            errMsg = StringUtils.strConcat("Failure: ", reason);
        }
    }
}