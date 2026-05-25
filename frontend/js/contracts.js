import { ORDER_ADDRESS, ESCROW_ADDRESS, DELIVERY_ADDRESS } from "./config.js";

import ORDER_ABI from "../abi/OrderABI.json" with { type: "json" };
import ESCROW_ABI from "../abi/EscrowABI.json" with { type: "json" };
import DELIVERY_ABI from "../abi/DeliveryABI.json" with { type: "json" };

import { signer } from "./wallet.js";

export function getContracts() {

    const orderContract = new ethers.Contract(
        ORDER_ADDRESS,
        ORDER_ABI,
        signer
    );

    const escrowContract = new ethers.Contract(
        ESCROW_ADDRESS,
        ESCROW_ABI,
        signer
    );

    const deliveryContract = new ethers.Contract(
        DELIVERY_ADDRESS,
        DELIVERY_ABI,
        signer
    );

    return {
        orderContract,
        escrowContract,
        deliveryContract
    };
}