import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.1/+esm";

export let provider;
export let signer;
export let walletAddress;

export async function connectWallet() {

    // Check Metamask availability
    if (!window.ethereum) {
        alert("MetaMask not installed");
        return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);

    // Requestaccount
    const accounts = await provider.send("eth_accounts", []);

    if (accounts.length === 0) {
        return;
    }

    // Store signer
    signer = await provider.getSigner();

    // Store current account
    walletAddress = await signer.getAddress();

    updateWalletDisplay();
}

export async function requestWalletConnection() {

    provider = new ethers.BrowserProvider(window.ethereum);

    await provider.send("eth_requestAccounts", []);

    signer = await provider.getSigner();

    walletAddress = await signer.getAddress();

    const network = await provider.getNetwork();

    if (network.chainId !== 11155111n) {
        alert("Please switch to Sepolia");
    }

    updateWalletDisplay();
}

// Update account address displayed
function updateWalletDisplay(text = walletAddress) {

    const el =
        document.getElementById("walletAddress");

    if (el) {
        el.innerText = text;
    }
}

// Detect Metamask wallet changes
window.ethereum.on("accountsChanged", async (accounts) => {

    if (accounts.length === 0) {

        walletAddress = null;
        signer = null;

        updateWalletDisplay("Not connected");

        return;
    }

    signer = await provider.getSigner();

    walletAddress = accounts[0];

    updateWalletDisplay(walletAddress);

    console.log("Wallet changed:", walletAddress);
});
