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

async function loadOrders() {

    await connectWallet();

    const { orderContract } = getContracts();

    const container =
        document.getElementById("ordersContainer");

    const count =
        await orderContract.orderCount();

    for (let i = 1; i <= count; i++) {

        const order =
            await orderContract.getOrderDetails(i);

        const div = document.createElement("div");

        div.className = "card";

        div.innerHTML = `
            <h3>Order #${i}</h3>

            <p>Status: ${statuses[order[9]]}</p>

            <a href="order.html?id=${i}">
                View Order
            </a>
        `;

        container.appendChild(div);
    }
}

loadOrders();