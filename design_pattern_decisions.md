# Design decisions

## Overview

I went through several iterations of designs for my project before arriving at the current structure. Due to the nature of the requirements, I settled on having the fundamental chess logic in a seperate library `Chess.sol` so that it could be easily reused by other contracts in the future (potentially when I implement tournaments), and the "interface" for my chess game be contained within its own contract `StandardGame.sol`.

## StandardGame

`StandardGame.sol` is the main entrance to my smart contracts. It contains all of the publicly available functionality that the front end needs for users to play games of chess:

-   searching and accepting of games
-   event emitting for games being accepted, moves, and checkmates
-   amalgamating move validation logic
-   getters for different game information and player information

Standard game also has a circuit breaker design pattern, using Openzeppelin's `Ownable.sol`.

## Chess

`Chess.sol` is the library containing all of the validation logic and concepts for the game. I decided to separate out this logic because it:

-   does not require any access to state variables, so it can be easily reused in different contexts
-   It became too unruly to manage within a single contract
