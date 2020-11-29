pragma solidity ^0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Chess.sol";

/// @title Unit tests for the Chess library
/// @author Christopher Givelas
contract TestChess {
    address player1 = address(100000);
    address player2 = address(100001);

    Chess.Game testGame;
    function beforeAll() public {
        Chess.Game storage board = testGame;

        testGame.board.players[player1].side = Chess.PlayerSide.White;
        testGame.board.players[player1].kingRank = 0;
        testGame.board.players[player1].kingFile = 7;

        testGame.board.players[player2].side = Chess.PlayerSide.Black;
        testGame.board.players[player2].kingRank = 6;
        testGame.board.players[player2].kingFile = 7;

        /**
            Test board initial configuration
            --------------------------------
         8 |         wr                     |
         7 |         wn      bb  bp  bp  bk |
         6 |             bp                 |
         5 |     bp  bq          wr      wp |
         4 |                 wp             |
         3 |                     wp         |
         2 |     br                      wp |
         1 |         wq                  wk |
            --------------------------------
             a   b   c   d   e   f   g   h
         */

        testGame.board.squares[0][2].isOccupied = true;
        testGame.board.squares[0][2].piece.pieceType = Chess.PieceType.Queen;
        testGame.board.squares[0][2].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[0][2].piece.hasMadeInitialMove = true;

        testGame.board.squares[0][7].isOccupied = true;
        testGame.board.squares[0][7].piece.pieceType = Chess.PieceType.King;
        testGame.board.squares[0][7].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[0][7].piece.hasMadeInitialMove = true;

        testGame.board.squares[1][1].isOccupied = true;
        testGame.board.squares[1][1].piece.pieceType = Chess.PieceType.Rook;
        testGame.board.squares[1][1].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[1][1].piece.hasMadeInitialMove = true;

        testGame.board.squares[1][7].isOccupied = true;
        testGame.board.squares[1][7].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[1][7].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[1][7].piece.hasMadeInitialMove = false;

        testGame.board.squares[2][5].isOccupied = true;
        testGame.board.squares[2][5].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[2][5].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[2][5].piece.hasMadeInitialMove = true;

        testGame.board.squares[3][4].isOccupied = true;
        testGame.board.squares[3][4].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[3][4].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[3][4].piece.hasMadeInitialMove = true;

        testGame.board.squares[4][1].isOccupied = true;
        testGame.board.squares[4][1].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[4][1].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[4][1].piece.hasMadeInitialMove = true;

        testGame.board.squares[4][2].isOccupied = true;
        testGame.board.squares[4][2].piece.pieceType = Chess.PieceType.Queen;
        testGame.board.squares[4][2].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[4][2].piece.hasMadeInitialMove = true;

        testGame.board.squares[4][5].isOccupied = true;
        testGame.board.squares[4][5].piece.pieceType = Chess.PieceType.Rook;
        testGame.board.squares[4][5].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[4][5].piece.hasMadeInitialMove = true;

        testGame.board.squares[4][7].isOccupied = true;
        testGame.board.squares[4][7].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[4][7].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[4][7].piece.hasMadeInitialMove = true;

        testGame.board.squares[5][3].isOccupied = true;
        testGame.board.squares[5][3].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[5][3].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[5][3].piece.hasMadeInitialMove = true;

        testGame.board.squares[6][2].isOccupied = true;
        testGame.board.squares[6][2].piece.pieceType = Chess.PieceType.Knight;
        testGame.board.squares[6][2].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[6][2].piece.hasMadeInitialMove = true;

        testGame.board.squares[6][4].isOccupied = true;
        testGame.board.squares[6][4].piece.pieceType = Chess.PieceType.Bishop;
        testGame.board.squares[6][4].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[6][4].piece.hasMadeInitialMove = true;

        testGame.board.squares[6][5].isOccupied = true;
        testGame.board.squares[6][5].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[6][5].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[6][5].piece.hasMadeInitialMove = false;

        testGame.board.squares[6][6].isOccupied = true;
        testGame.board.squares[6][6].piece.pieceType = Chess.PieceType.Pawn;
        testGame.board.squares[6][6].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[6][6].piece.hasMadeInitialMove = false;

        testGame.board.squares[6][7].isOccupied = true;
        testGame.board.squares[6][7].piece.pieceType = Chess.PieceType.King;
        testGame.board.squares[6][7].piece.side = Chess.PlayerSide.Black;
        testGame.board.squares[6][7].piece.hasMadeInitialMove = true;

        testGame.board.squares[7][2].isOccupied = true;
        testGame.board.squares[7][2].piece.pieceType = Chess.PieceType.Rook;
        testGame.board.squares[7][2].piece.side = Chess.PlayerSide.White;
        testGame.board.squares[7][2].piece.hasMadeInitialMove = true;

        testGame.gameId = 0;
        testGame.currentTurn = Chess.PlayerSide.White;
        testGame.started = true;
        testGame.ended = false;
        testGame.winner = address(0);
        testGame.moveCount = 0;
    }

    function testPositionIsThreatened_h7_blackKing() public {
        Assert.isTrue(
            !Chess.positionIsThreatened(6,7, testGame.board, Chess.PlayerSide.Black),
            "Position shouldn't be threatened"
        );
    }

    function testPositionIsThreatened_g7_blackPawn() public {        
        Assert.isTrue(
            !Chess.positionIsThreatened(6,6, testGame.board, Chess.PlayerSide.Black),
            "Position shouldn't be threatened"
        );
    }

    function testPositionIsThreatened_f7_blackPawn() public {
        Assert.isTrue(
            Chess.positionIsThreatened(6,5, testGame.board, Chess.PlayerSide.Black),
            "Position should be threatened"
        );
    }

    function testPositionIsThreatened_b5_blackPawn() public {
        Assert.isTrue(
            Chess.positionIsThreatened(4,2, testGame.board, Chess.PlayerSide.Black),
            "Position should be threatened"
        );
    }

    function testPositionIsThreatened_b2_blackRook() public {
        Assert.isTrue(
            Chess.positionIsThreatened(1,1, testGame.board, Chess.PlayerSide.Black),
            "Position should be threatened"
        );
    }

    function testPositionIsThreatened_c8_whiteRook() public {
        Assert.isTrue(
            !Chess.positionIsThreatened(7,2, testGame.board, Chess.PlayerSide.White),
            "Position shouldn't be threatened"
        );
    }

    function testPositionIsThreatened_f5_whiteRook() public {
        Assert.isTrue(
            Chess.positionIsThreatened(4,5, testGame.board, Chess.PlayerSide.White),
            "Position should be threatened"
        );
    }

    function testPositionIsThreatened_c1_whiteQueen() public {
        Assert.isTrue(
            Chess.positionIsThreatened(0,2, testGame.board, Chess.PlayerSide.White),
            "Position should be threatened"
        );
    }
}