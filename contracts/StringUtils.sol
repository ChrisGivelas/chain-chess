pragma solidity ^0.6.0;

library StringUtils {
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        string[] memory strings = new string[](2);

        strings[0] = _a;
        strings[1] = _b;

        return strConcatArray(strings);
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        string[] memory strings = new string[](3);

        strings[0] = _a;
        strings[1] = _b;
        strings[2] = _c;

        return strConcatArray(strings);
    }

    // Adapted from https://github.com/provable-things/ethereum-api/blob/9f34daaa550202c44f48cdee7754245074bde65d/oraclizeAPI_0.5.sol#L959
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e, string memory _f) internal pure returns (string memory _concatenatedString) {
        string[] memory strings = new string[](6);

        strings[0] = _a;
        strings[1] = _b;
        strings[2] = _c;
        strings[3] = _d;
        strings[4] = _e;
        strings[5] = _f;

        return strConcatArray(strings);
    }

    function strConcatArray(string[] memory strings) internal pure returns (string memory) {
        if(strings.length == 0) return "";

        bytes[] memory byte_strings = new bytes[](strings.length);
        uint length = 0;
        for(uint i = 0; i < strings.length; i++) {
            byte_strings[i] = bytes(strings[i]);
            length += byte_strings[i].length;
        }

        bytes memory bytesConcatenated = bytes(new string(length));

        uint byte_string_char_iter = 0;
        uint concatenated_bytes_iter = 0;
        for(uint byte_string_iter = 0; byte_string_iter < byte_strings.length; byte_string_iter++) {
            bytes memory currentStringBytes = byte_strings[byte_string_iter];

            for (byte_string_char_iter = 0; byte_string_char_iter < currentStringBytes.length; byte_string_char_iter++) {
                bytesConcatenated[concatenated_bytes_iter++] = currentStringBytes[byte_string_char_iter];
            }
        }
        return string(bytesConcatenated);
    }
}