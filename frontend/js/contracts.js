import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.1/+esm";

// Import wallet data
import * as wallet from "./wallet.js";

// Retrieve contract ABIs
import ORDER_ABI from "../abi/orderABI.json" with { type: "json" };
import ESCROW_ABI from "../abi/escrowABI.json" with { type: "json" };
import DELIVERY_ABI from "../abi/deliveryABI.json" with { type: "json" };

// Set contract addresses
const ORDER_ADDRESS = "0x0992a45DcAeaC3842a3064616F78CB04148fF88d";
const ESCROW_ADDRESS = "0xa9543dE838cFA8bE222960FCfeb69D664d81B0f6";
const DELIVERY_ADDRESS = "0x41d5F310ec376CCA0A0b2E084ad70BeD84FABFD0";

// Create contract objects
export function getOrderContract() {

    // Check if wallet is connected
    if (!wallet.signer) {
        throw new Error("Wallet not connected");
    }

    return new ethers.Contract(
        ORDER_ADDRESS,
        ORDER_ABI,
        wallet.signer
    );
}

export function getEscrowContract() {

    if (!wallet.signer) {
        throw new Error("Wallet not connected");
    }

    return new ethers.Contract(
        ESCROW_ADDRESS,
        ESCROW_ABI,
        wallet.signer
    );
}

export function getDeliveryContract() {

    if (!wallet.signer) {
        throw new Error("Wallet not connected");
    }

    return new ethers.Contract(
        DELIVERY_ADDRESS,
        DELIVERY_ABI,
        wallet.signer
    );
}
