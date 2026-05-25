import { connectWallet } from "./wallet.js";
import { getContracts } from "./contracts.js";

const statuses = [
    "Created",
    "Paid",
    "Shipped",
    "In Transit",
    "Delivered",
    "Completed",
    "Failed",
    "Refunded"
];

const params =
    new URLSearchParams(window.location.search);

const orderId = params.get("id");

async function loadOrder() {

    await connectWallet();

    const {
        orderContract,
        escrowContract,
        deliveryContract
    } = getContracts();

    const order =
        await orderContract.getOrderDetails(orderId);

    document.getElementById("orderInfo")
    .innerHTML = `
        <p>Customer: ${order[0]}</p>
        <p>Retailer: ${order[1]}</p>
        <p>Supplier: ${order[2]}</p>
        <p>Product: ${order[4]}</p>
        <p>Quantity: ${order[5]}</p>
        <p>Price: ${order[6]}</p>
        <p>Status: ${statuses[order[9]]}</p>
    `;

    document
    .getElementById("depositButton")
    .onclick = async () => {

        const tx =
            await escrowContract.depositPayment(orderId, {
                value: order[6]
            });

        await tx.wait();

        alert("Payment deposited");
    };

    document
    .getElementById("confirmButton")
    .onclick = async () => {

        const tx =
            await escrowContract.confirmDelivery(orderId);

        await tx.wait();

        alert("Delivery confirmed");
    };

    document
    .getElementById("releaseButton")
    .onclick = async () => {

        const tx =
            await escrowContract.releaseFunds(orderId);

        await tx.wait();

        alert("Funds released");
    };

    document
    .getElementById("refundButton")
    .onclick = async () => {

        const tx =
            await escrowContract.refund(orderId);

        await tx.wait();

        alert("Refunded");
    };

    document
    .getElementById("shippedButton")
    .onclick = async () => {

        const tx =
            await deliveryContract.markAsShipped(orderId);

        await tx.wait();

        alert("Marked shipped");
    };

    document
    .getElementById("transitButton")
    .onclick = async () => {

        const tx =
            await deliveryContract.markAsInTransit(orderId);

        await tx.wait();

        alert("Marked in transit");
    };

    document
    .getElementById("deliveredButton")
    .onclick = async () => {

        const tx =
            await deliveryContract.markAsDelivered(orderId);

        await tx.wait();

        alert("Marked delivered");
    };
}

loadOrder();