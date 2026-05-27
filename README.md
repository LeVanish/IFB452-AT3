# Delivery Escrow dApp

### IFB452 AT3 Blackhain Project

#### Team 106:
- Ivan Ostapenko (n11421860)
- Arjun Ramesh Nair (n11530405)

##### Application purpose
- Securely store order payment in an escrow
- Release or refund the deposit when certain conditions are fulfilled
- Store and update order status, including delivery shipment status

##### Application structure
```
IFB452-AT3
├── contracts/
│   ├── delivery.sol
│   ├── escrow.sol
│   └── order.sol
│
├── frontend/
│   ├── abi/
│   │   ├── deliveryABI.json
│   │   ├── escrowABI.json
│   │   └── orderABI.json
│   │
│   ├── js/
│   │   ├── app.js
│   │   ├── contracts.js
│   │   └── wallet.js
│   │
│   ├── index.html
│   ├── package-lock.json
│   └── package.json
└── README.md
```

## Application deployment guide
Contract deployment
Currently used contracts are already deployed on the Sepolia testnet. If you want to deploy the contracts yourself:
- Deploy OrderContract
- Using OrderContract address, deploy EscrowContract and DeliveryContract
- Use EscrowContract and DeliveryContract addresses, set them using respective functions in OrderContract
- The contracts should be connected and able to interact with each other
- Change contract addresses in contracts.js to newly deployed contract addresses

Server deployment
- Node.js should be installed. Node can be installed at https://nodejs.org/en/download 
- Change current directory to "/IFB452-AT3/frontend"
- In terminal, enter "npx serve"

The local server should be running on "http://localhost:3000"