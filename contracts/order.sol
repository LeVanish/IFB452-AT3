// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TODO
// Change getOrderDetails so it returns whole tuple. In remix it is displayed poely, but it can still be displayed properly on front end
// Break down status updates in different functions
// Restict delivery provider assignment to only before the shipment is commenced

/*
    Order Contract:

    - Stores order information
    - Manages order status
    - Manages retailers
    - Allows other contracts to interact with orders
*/

contract OrderContract {

    // Owner
    address public owner;

    // Approved retailers list
    mapping(address => bool) public retailers;

    // External contracts, set after Order contract is deployed
    address public escrowContract;
    address public deliveryContract;

    // Order statuses to track order lifecycle
    enum OrderStatus { 
        Created, 
        Paid, 
        Shipped, 
        InTransit, 
        Delivered, 
        Completed,
        Failed,
        Refunded
    }

    // Order information
    struct Order {
        uint256 orderId;
        
        // Stakeholders
        address customer;
        address retailer;
        address supplier;
        address deliveryProvider;

        // Product info
        string productName;
        uint256 quantity;
        uint256 price;

        // Timestamps
        uint256 createdAt;
        uint256 deliveredAt;

        // Order status
        OrderStatus status;
    }

    // Mapping: orderId => Order and total order count
    mapping(uint256 => Order) public orders;
    uint256 public orderCount;

    // Events for blockchain logs
    event RetailerAdded(address retailer);
    event RetailerRemoved(address retailer);

    event OrderCreated(uint256 orderId, address customer, address retailer, address supplier, uint256 quantity, uint256 price);
    event OrderDetailsUpdated(uint256 orderId, string productName, uint256 quantity, uint256 price);
    event OrderStatusUpdated(uint256 orderId, OrderStatus status);

    constructor() {
        owner = msg.sender;

        // Contract deployer is considered a first retailer
        retailers[owner] = true;
    }

    // Resticts access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    // Restricts access to approved retailers only
    modifier onlyRetailer() {
        require(retailers[msg.sender], "Only retailer can do this");
        _;
    }

    // Adds new approved retailer
    function addRetailer(address _retailer) public onlyOwner {
        require(_retailer != address(0), "Invalid address");

        retailers[_retailer] = true;
        emit RetailerAdded(_retailer);
    }
    
    // Removes retailer from approved list
    function removeRetailer(address _retailer) public onlyOwner {
        require(_retailer != address(0), "Invalid address");

        retailers[_retailer] = false;
        emit RetailerRemoved(_retailer);
    }

    // Assigns delivery provider to an order
    function setDeliveryProvider(uint256 _orderId, address _deliveryProvider) public {
        
        // Retrieve order data
        Order storage o = orders[_orderId];

        // Validate sender and provided address
        require(
            msg.sender == o.retailer ||
            msg.sender == o.supplier,
            "Not authorised to set delivery provider"
        );
        require(
            o.status == OrderStatus.Created ||
            o.status == OrderStatus.Paid,
            "Delivery already commenced"
        );
        require(_deliveryProvider != address(0), "Provided address should be valid");

        o.deliveryProvider = _deliveryProvider;
    }   

    // Links Order contract to Escrow contract
    function setEscrowContract(address _escrowContract) public onlyOwner {
        escrowContract = _escrowContract;
    }

    // Links Order contract to Delivery contract
    function setDeliveryContract(address _deliveryContract) public onlyOwner {
        deliveryContract = _deliveryContract;
    }

    // Creates a new order. Only approved retailers can create order
    function createOrder(
        address _customer,
        address _supplier,
        string memory _productName,
        uint256 _quantity,
        uint256 _price
    ) public onlyRetailer {
        require(
            _customer != address(0) &&
            _supplier != address(0),
            "All addresses should be valid"
        );

        orderCount++;

        // Create and store new order
        orders[orderCount] = Order(
            orderCount,
            _customer,
            msg.sender,
            _supplier,
            address(0), // Delivery provider is assigned later
            _productName,
            _quantity,
            _price,
            block.timestamp,
            0, // DeliveredAt is assignmed upon order delivery
            OrderStatus.Created
        );
        emit OrderCreated(orderCount, _customer, msg.sender, _supplier, _quantity, _price);
    }

    // Updates editable order details. Only order retailer is allowed to update details
    function updateOrderDetails(
        uint256 _orderId,
        string memory _productName,
        uint256 _quantity,
        uint256 _price
    ) public {
        // Retrieve order data
        Order storage o = orders[_orderId];

        // Verify aender, if order exists, and if money has been deposited
        require(o.retailer == msg.sender, "Unathorised sender");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Created, "Order has already been paid");

        // Update order details
        o.productName = _productName;
        o.quantity = _quantity;
        o.price = _price;
        emit OrderDetailsUpdated(_orderId, _productName, _quantity, _price);
    }

    // Updates order status. Used by retailer, supplier, and other contracts
    function updateOrderStatus(uint256 _orderId, OrderStatus _status) public {
        // Retrieve order data
        Order storage o = orders[_orderId];

        // Verify sender and if order exists
        require(
            msg.sender == o.retailer ||
            msg.sender == o.supplier ||
            msg.sender == escrowContract ||
            msg.sender == deliveryContract,
            "Not authorised"
        );
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");

        // If order status is changed to delivered, record timestamp in deliveredAt
        if (_status == OrderStatus.Delivered){
            o.deliveredAt = block.timestamp;
        }

        o.status = _status;
        emit OrderStatusUpdated(_orderId, _status);
    }

    // Returns all order details
    function getOrderDetails(uint256 _orderId)
        public
        view
        returns (
            address customer,
            address retailer,
            address supplier,
            address deliveryProvider,
            string memory productName,
            uint256 quantity,
            uint256 price,
            uint256 createdAt,
            uint256 deliveredAt,
            OrderStatus status
        )
    {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        return (o.customer, o.retailer, o.supplier, o.deliveryProvider, o.productName, o.quantity, o.price, o.createdAt, o.deliveredAt, o.status);
    }

    // Returns only order status
    function getOrderStatus(uint256 _orderId) public view returns (OrderStatus){
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        return orders[_orderId].status;
    }
}