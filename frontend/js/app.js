import {
    connectWallet,
    requestWalletConnection
} from "./wallet.js";

import {
    getOrderContract,
    getEscrowContract,
    getDeliveryContract
} from "./contracts.js";

const orderStatuses = [
    "Created",
    "Paid",
    "Shipped",
    "InTransit",
    "Delivered",
    "Completed",
    "Failed",
    "Refunded"
];


window.addEventListener("load", async () => {
    await connectWallet();
});

document.getElementById("connectBtn")
.addEventListener("click", async () => {

    await requestWalletConnection();
});

document.getElementById("createOrderBtn")
.addEventListener("click", async () => {

    try {

        const orderContract = getOrderContract();

        const customer =
            document.getElementById("customer").value;

        const supplier =
            document.getElementById("supplier").value;

        const productName =
            document.getElementById("productName").value;

        const quantity =
            document.getElementById("quantity").value;

        const price =
            document.getElementById("price").value;

        const tx = await orderContract.createOrder(
            customer,
            supplier,
            productName,
            quantity,
            price
        );

        await tx.wait();

        alert("Order created");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("assignDeliveryBtn")
.addEventListener("click", async () => {

    try {

        const orderContract = getOrderContract();

        const orderId =
            document.getElementById("assignOrderId").value;

        const deliveryProvider =
            document.getElementById("deliveryProvider").value;

        const tx =
            await orderContract.setDeliveryProvider(
                orderId,
                deliveryProvider
            );

        await tx.wait();

        alert("Delivery provider assigned");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("viewOrderBtn")
.addEventListener("click", async () => {

    try {

        const orderContract = getOrderContract();

        const orderId =
            document.getElementById("viewOrderId").value;

        const order =
            await orderContract.getOrderDetails(orderId);

        const html = `
            <p>Customer: ${order[0]}</p>
            <p>Retailer: ${order[1]}</p>
            <p>Supplier: ${order[2]}</p>
            <p>Delivery Provider: ${order[3]}</p>
            <p>Product: ${order[4]}</p>
            <p>Quantity: ${order[5]}</p>
            <p>Price: ${order[6].toString()}</p>
            <p>Status: ${orderStatuses[Number(order[9])]}</p>
        `;

        document.getElementById("orderDetails")
            .innerHTML = html;

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("depositBtn")
.addEventListener("click", async () => {

    try {

        const orderContract = getOrderContract();
        const escrowContract = getEscrowContract();

        const orderId =
            document.getElementById("depositOrderId").value;

        const order =
            await orderContract.getOrderDetails(orderId);

        const price = order[6];

        const tx =
            await escrowContract.depositPayment(
                orderId,
                {
                    value: price
                }
            );

        await tx.wait();

        alert("Payment deposited");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("confirmDeliveryBtn")
.addEventListener("click", async () => {

    try {

        const escrowContract = getEscrowContract();

        const orderId =
            document.getElementById("depositOrderId").value;

        const tx =
            await escrowContract.confirmDelivery(orderId);

        await tx.wait();

        alert("Delivery confirmed");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("releaseFundsBtn")
.addEventListener("click", async () => {

    try {

        const escrowContract = getEscrowContract();

        const orderId =
            document.getElementById("depositOrderId").value;

        const tx =
            await escrowContract.releaseFunds(orderId);

        await tx.wait();

        alert("Funds released");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("refundBtn")
.addEventListener("click", async () => {

    try {

        const escrowContract = getEscrowContract();

        const orderId =
            document.getElementById("depositOrderId").value;

        const tx =
            await escrowContract.refund(orderId);

        await tx.wait();

        alert("Refund successful");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("shippedBtn")
.addEventListener("click", async () => {

    try {

        const deliveryContract =
            getDeliveryContract();

        const orderId =
            document.getElementById("deliveryOrderId").value;

        const tx =
            await deliveryContract.markAsShipped(orderId);

        await tx.wait();

        alert("Marked as shipped");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("transitBtn")
.addEventListener("click", async () => {

    try {

        const deliveryContract =
            getDeliveryContract();

        const orderId =
            document.getElementById("deliveryOrderId").value;

        const tx =
            await deliveryContract.markAsInTransit(orderId);

        await tx.wait();

        alert("Marked as in transit");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("deliveredBtn")
.addEventListener("click", async () => {

    try {

        const deliveryContract =
            getDeliveryContract();

        const orderId =
            document.getElementById("deliveryOrderId").value;

        const tx =
            await deliveryContract.markAsDelivered(orderId);

        await tx.wait();

        alert("Marked as delivered");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("failOrderBtn")
.addEventListener("click", async () => {

    const confirmed =
        confirm("Are you sure you want to fail this order?");

    if (!confirmed) {
        return;
    }

    try {

        const orderContract = getOrderContract();

        const orderId =
            document.getElementById("failOrderId").value;

        const tx =
            await orderContract.markAsFailed(orderId);

        await tx.wait();

        alert("Order marked as failed");

    } catch(err) {

        alert(err.reason || err.message);
    }
});