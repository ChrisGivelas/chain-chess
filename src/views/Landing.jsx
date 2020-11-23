import React from "react";
import { Button } from "rimble-ui";

function Landing({ connectWallet }) {
    return (
        <header className="App-header">
            <h1>
                ♘ Welcome to ChainChess, a decentalized chess battleground! ♔
            </h1>

            <Button onClick={connectWallet}>
                Connect metamask wallet to start playing!
            </Button>
        </header>
    );
}

export default Landing;
