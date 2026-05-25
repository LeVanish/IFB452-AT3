// This code is main controller of the front end.
// It used for handling button clicks and form submissions, connection Ui to contracts and establishing front end logic

import { connectWallet, requestWalletConnection } from "./wallet.js";

import { getOrderContract, getEscrowContract, getDeliveryContract } from "./contracts.js";

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

// =========================================== Wallet actions ===========================================
window.addEventListener("load", async () => {
    await connectWallet();
});


document.getElementById("connectBtn").addEventListener("click", async () => {

    await requestWalletConnection();
});

// =========================================== Order actions ===========================================
document.getElementById("createOrderBtn").addEventListener("click", async () => {
    try {

        const orderContract = getOrderContract();

        const customer = document.getElementById("customer").value;

        const supplier = document.getElementById("supplier").value;

        const productName = document.getElementById("productName").value;

        const quantity = document.getElementById("quantity").value;

        const price = document.getElementById("price").value;

        const transaction = await orderContract.createOrder(
            customer,
            supplier,
            productName,
            quantity,
            price
        );

        await transaction.wait();

        alert("Order created");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("assignDeliveryBtn").addEventListener("click", async () => {
    try {

        const orderContract = getOrderContract();

        const orderId = document.getElementById("assignOrderId").value;

        const deliveryProvider = document.getElementById("deliveryProvider").value;

        const transaction = await orderContract.setDeliveryProvider(
            orderId,
            deliveryProvider
        );

        await transaction.wait();

        alert("Delivery provider assigned");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("loadOrdersBtn").addEventListener("click", async () => {
        try {

            const contract = getOrderContract();

            const count = Number(await contract.orderCount());

            if (count === 0) {

                container.innerHTML = "No orders exist";
                return;
            }

            let html = "";

            for (let i = 1; i <= count; i++) {

                const order = await contract.getOrderDetails(i);

                html += `
                    <div class="order-card">

                        <strong>Order #${i}</strong>
                        <br>

                        Product: ${order.productName}
                        <br>

                        Status: ${orderStatuses[order.status]}
                    </div>
                    <br>
                `;
            }

            document.getElementById("ordersList").innerHTML = html;

        } catch(error) {

            alert(error.reason || error.message);
        }
    });

document.getElementById("viewOrderBtn").addEventListener("click", async () => {
    try {

        const orderContract = getOrderContract();

        const orderId = document.getElementById("viewOrderId").value;

        const order = await orderContract.getOrderDetails(orderId);

        let deliveryProviderData = "No delivery provider assigned";

        if (order.deliveryProvider !== "0x0000000000000000000000000000000000000000") {

            deliveryProviderData = order.deliveryProvider;
        }


        const created = new Date(Number(order.createdAt) * 1000).toLocaleString();
        

        let delivered = "Delivery is not finished";

        if (Number(order.deliveredAt) !== 0) {

            const deliveredDate = new Date(Number(order.deliveredAt) * 1000);

            delivered = deliveredDate.toLocaleString();
        }

        const html = `
            <p>Customer: ${order[0]}</p>
            <p>Retailer: ${order[1]}</p>
            <p>Supplier: ${order[2]}</p>
            <p>Delivery Provider: ${deliveryProviderData}</p>
            <p>Product: ${order[4]}</p>
            <p>Quantity: ${order[5]}</p>
            <p>Price: ${order[6].toString()}</p>
            <p>Created At: ${created}</p>
            <p>Delivered At: ${delivered}</p>
            <p>Status: ${orderStatuses[Number(order[9])]}</p>
        `;

        document.getElementById("orderDetails").innerHTML = html;

    } catch(err) {

        alert(err.reason || err.message);
    }
});

// =========================================== Escrow Actions ===========================================
document.getElementById("depositBtn").addEventListener("click", async () => {
    try {

        const orderContract = getOrderContract();
        const escrowContract = getEscrowContract();

        const orderId = document.getElementById("depositOrderId").value;

        const order = await orderContract.getOrderDetails(orderId);

        const price = order[6];

        const transaction = await escrowContract.depositPayment(
                orderId,
                {
                    value: price
                }
            );

        await transaction.wait();

        alert("Payment deposited");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("confirmDeliveryBtn").addEventListener("click", async () => {
    try {

        const escrowContract = getEscrowContract();

        const orderId = document.getElementById("depositOrderId").value;

        const transaction = await escrowContract.confirmDelivery(orderId);

        await transaction.wait();

        alert("Delivery confirmed");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("releaseFundsBtn").addEventListener("click", async () => {
    try {

        const escrowContract = getEscrowContract();

        const orderId = document.getElementById("depositOrderId").value;

        const transaction = await escrowContract.releaseFunds(orderId);

        await transaction.wait();

        alert("Funds released");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("refundBtn").addEventListener("click", async () => {
    try {

        const escrowContract = getEscrowContract();

        const orderId = document.getElementById("depositOrderId").value;

        const transaction = await escrowContract.refund(orderId);

        await transaction.wait();

        alert("Refund successful");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

// =========================================== Delivery actions ===========================================
document.getElementById("shippedBtn").addEventListener("click", async () => {
    try {

        const deliveryContract = getDeliveryContract();

        const orderId = document.getElementById("deliveryOrderId").value;

        const transaction = await deliveryContract.markAsShipped(orderId);

        await transaction.wait();

        alert("Marked as shipped");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("transitBtn").addEventListener("click", async () => {
    try {

        const deliveryContract = getDeliveryContract();

        const orderId = document.getElementById("deliveryOrderId").value;

        const transaction = await deliveryContract.markAsInTransit(orderId);

        await transaction.wait();

        alert("Marked as in transit");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

document.getElementById("deliveredBtn").addEventListener("click", async () => {
    try {

        const deliveryContract = getDeliveryContract();

        const orderId = document.getElementById("deliveryOrderId").value;

        const transaction = await deliveryContract.markAsDelivered(orderId);

        await transaction.wait();

        alert("Marked as delivered");

    } catch(err) {

        alert(err.reason || err.message);
    }
});

// Order Fail action
document.getElementById("failOrderBtn").addEventListener("click", async () => {

    const confirmed = confirm("Are you sure you want to fail this order?");

    if (!confirmed) {
        return;
    }

    try {

        const orderContract = getOrderContract();

        const orderId = document.getElementById("failOrderId").value;

        const transaction = await orderContract.markAsFailed(orderId);

        await transaction.wait();

        alert("Order marked as failed");

    } catch(err) {

        alert(err.reason || err.message);
    }
});