import Web3 from "web3";
import { Blockie } from "rimble-ui";
import randomColor from "randomcolor";

export const updateWeb3AndReturnWeb3Provider = () => {
    var web3Provider;
    if (typeof window.web3 !== "undefined") {
        web3Provider = window.web3.currentProvider;
    } else {
        web3Provider = new Web3.providers.HttpProvider("http://localhost:8545");
    }

    window.web3 = new Web3(web3Provider);
    window.web3.eth.handleRevert = true;

    return web3Provider;
};

export const checksumAddr = (addr) => window.web3.utils.toChecksumAddress(addr);

export const getAddressBlockie = (addr) => {
    const [color, bgcolor, spotcolor] = randomColor({
        count: 3,
        seed: addr,
        luminosity: "dark",
    });
    return (
        <Blockie
            opts={{
                seed: addr,
                color,
                bgcolor,
                spotcolor,
                size: 10,
                scale: 4,
            }}
        />
    );
};
