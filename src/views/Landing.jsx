import React from "react";
import ButtonWithLoader from "../components/buttonWithLoader";

function Landing({ connectWallet, isLoading }) {
    return (
        <header className="App-header">
            <h1>
                ♘ Welcome to ChainChess, a decentalized chess battleground! ♔
            </h1>

            <ButtonWithLoader
                isLoading={isLoading}
                onClick={connectWallet}
                text="Connect metamask wallet to start playing!"
            ></ButtonWithLoader>
        </header>
    );
}

export default Landing;
