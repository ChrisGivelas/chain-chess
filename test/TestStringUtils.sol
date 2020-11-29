pragma solidity ^0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StringUtils.sol";

/// @title Unit tests for the String Utils library
/// @author Christopher Givelas
contract TestStringUtils {
    function testStrConcat() public {
        Assert.equal(StringUtils.strConcat("Hello ", "World!"), "Hello World!", "Incorrect string returned");
        Assert.equal(StringUtils.strConcat("Hello", " ", "World!"), "Hello World!", "Incorrect string returned");
        Assert.equal(StringUtils.strConcat("This ", "is ", "a ", "really ", "cool ", "sentence."), "This is a really cool sentence.", "Incorrect string returned");

        string[] memory long_list = new string[](17);
        for(uint i = 0; i < long_list.length - 1; i++) {long_list[i] = "Na";}
        long_list[16] = "Batman!";

        Assert.equal(StringUtils.strConcatArray(long_list), "NaNaNaNaNaNaNaNaNaNaNaNaNaNaNaNaBatman!", "Golly Gee Batman!");
    }
}