# Chain-Chess

## Overview

Chain-chess is a decentralized chess game. It allows users to start games with others, store information about win/loss statistics, and validate moves and board states. I chose this idea because I thought the complexity of programming a chess game in solidity would exemplify my skills (and I believe it still does), but I unfortunately am missing some of my original requirements that I think would make this project even better. Originally I intended to add tournament staking functionality and staking for individual games, but implementing the chess logic turned out to be a difficult enough task. I'm intending to add these features in the near future.

## Project Structure

My project structure is seperated into two main areas:

1. The front end is contained in the typcial React `src` and `public` directories. Using npm to install packages for the front end results in `node_modules` and `package.json` existing. Within `/src`, `/views` contains the different pages in the flow for my dapp, `/components` contains some smaller reusable react components, and `/utils` contains a myriad of different tools for the front end including routing, setting up web3, and parsing responses from the connected network. `/assets` contains only 2 media assets for the UI. And lastly, `standardGame.js` is a modularized script containing functions for all async contract calls of `StandardGame.sol`

2. The blockchain related code is contained in the typical truffle directories `contracts`, `migrations`, and `test` at the root level of the project, and `truffle-config.js` stores the configuration information for truffle

My compiled contracts go into `/src/contracts` so that their abi's are accesible to the frontend.

## How to run

Before running make sure you have [node/npm](https://nodejs.org/en/) (tested with node version 14.15.1) and [truffle](https://www.trufflesuite.com/docs/truffle/getting-started/installation) (tested with version 5.1.53) installed on your machine.

This project was predominantly built on a windows machine, but was also tested on an ubuntu 20.04 VM. If you are running on windows, no changes to the code should be needed for this to work. If you are running on unix-based machines, change the file name of `truffle-config.js` to `truffle.js`.

Begin by running npm install in the root of the project directory. This will pull all require dependencies for the frontend.

To start the project, first run `truffle develop` to start up the truffle development console. Run `migrate --reset` to compile and migrate the contract to your local chain started by truffle (alternatively, you can use `ganache-cli` to start up a development chain and migrate with `truffle migrate --reset`. Just make sure the port of your ganache instance matches 8545). Once done, you then run `npm start` to start up the webpack dev-server embedded within this create-react-app project.

Navigate to localhost:3000 to start playing!

## Notable code

The most important externally facing code is the movePiece function in `StandardGame.sol`. It makes use of all of the logic throughout the `Chess.sol` library to validate moves with respect to the board state, and update the board state if it is a valid move.

## Known Bugs/Missing Requirements/Improvements

Due to my underestimation of the complexity of move validation and board state validation(checking for checkmate), along with the fact that I was learning solidity and its pitfalls throughout, I was unable to complete some of the aspects of chess:

_Castling_ - This would be easily implemented within a separate function in Chess.sol.

_Proper Checkmate validation_ - Currently, checkmate is calculated by checking if the square a king is on and all the squares around them are being threatened. But in order to properly calculate checkmate, one must check every possible move that any piece from that king's side can make, possibly capturing the threatening piece or blocking. I mainly left out this aspect becuase it would be expensive to caluclate on-chain within the `movePiece` function, but also because it was logically difficult to realize in the time given. When I implement this in the future, I will most likely try to use an oracle to validate checkmate board state.

_En passant_ - Easily added to `validatePawnMove` in Chess.sol

_Piece promotion_ - This would be interesting to implement. On pawn move to the opposing end rank, I would need to recieve an identifier from the front end denoting the new piece to replace the pawn. I would then need to perform the piece validation as normal on the pawn, change the piece type to the one specified, and then calculate if the opposing king is now in check considering the new piece on the board. This could be done either by overloading the `movePiece` function with a new one taking in promotion piece type as well.
