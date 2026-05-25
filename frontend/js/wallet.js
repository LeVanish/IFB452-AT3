export let provider;
export let signer;
export let walletAddress;

export async function connectWallet() {

    if (!window.ethereum) {
        alert("MetaMask not installed");
        return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);

    try {

        await provider.send("eth_requestAccounts", []);

    } catch (err) {

        alert("Wallet connection rejected");
    }

    signer = await provider.getSigner();

    walletAddress = await signer.getAddress();

    return walletAddress;
}