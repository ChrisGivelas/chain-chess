import React from "react";
import { MetaMaskButton } from "rimble-ui";
import BlackKing from "../assets/bk";
import WhiteKing from "../assets/wk";

function Landing({ connectWallet }) {
    return (
        <header className="App-header">
            <h1>Welcome to ChainChess, a decentalized chess battleground! </h1>
            <div className="meta-mask-button-holder">
                <BlackKing />
                <MetaMaskButton onClick={connectWallet}>
                    Connect metamask wallet to start playing!
                </MetaMaskButton>
                <WhiteKing />
            </div>
        </header>
    );
}

export default Landing;
