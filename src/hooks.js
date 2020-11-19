import Web3 from "web3";
import TruffleContract from "@truffle/contract";
import { useState, useEffect } from "react";

export const useWeb3 = async () => {
    const [web3Provider, setWeb3Provider] = useState(null);

    useEffect(() => {
        if (web3Provider === null) {
            if (typeof window.web3 !== "undefined") {
                setWeb3Provider(window.web3.currentProvider);
            } else {
                setWeb3Provider(
                    new Web3.providers.HttpProvider("http://localhost:8545")
                );
            }

            window.web3 = new Web3(web3Provider);
        }
    }, [web3Provider]);

    return web3Provider;
};

export const useContract = async (contractName) => {
    const web3Provider = useWeb3();

    return await import(`./contracts/${contractName}.json`).then((data) => {
        var Contract = TruffleContract(data.default);
        Contract.setProvider(web3Provider);
        console.log(Contract);

        return Contract;
    });
};
