import { connectWallet } from "./wallet.js";
import { getContracts } from "./contracts.js";

document
.getElementById("connectButton")
.addEventListener("click", async () => {

    const address = await connectWallet();

    document.getElementById("walletAddress")
    .innerText = address;
});

document
.getElementById("createOrderForm")
.addEventListener("submit", async (e) => {

    e.preventDefault();

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

    try {

        const { orderContract } = getContracts();

        const tx = await orderContract.createOrder(
            customer,
            supplier,
            productName,
            quantity,
            price
        );

        await tx.wait();

        alert("Order created");

    } catch (err) {

        console.error(err);

        alert("Transaction failed");
    }
});