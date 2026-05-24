// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TODO
// Change getOrderDetails so it returns whole tuple. In remix it is displayed poorly, but it can still be displayed properly on front end
// Break down status updates in different functions

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

        // Validate sender, order and provided address
        require(
            msg.sender == o.retailer ||
            msg.sender == o.supplier,
            "Not authorised to set delivery provider"
        );
        require(_orderId > 0 &&_orderId <= orderCount, "Invalid order ID");
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
            0, // deliveredAt is assigned upon order delivery
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

        // Verify sender, if order exists, and if money has been deposited
        require(o.retailer == msg.sender, "Unathorised sender");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Created, "Order has already been paid");

        // Update order details
        o.productName = _productName;
        o.quantity = _quantity;
        o.price = _price;
        emit OrderDetailsUpdated(_orderId, _productName, _quantity, _price);
    }

    // // Updates order status. Used by retailer, supplier, and other contracts
    // function updateOrderStatus(uint256 _orderId, OrderStatus _status) public {
    //     // Retrieve order data
    //     Order storage o = orders[_orderId];

    //     // Verify sender and if order exists
    //     require(
    //         msg.sender == o.retailer ||
    //         msg.sender == o.supplier ||
    //         msg.sender == escrowContract ||
    //         msg.sender == deliveryContract,
    //         "Not authorised"
    //     );
    //     require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");

    //     // If order status is changed to delivered, record timestamp in deliveredAt
    //     if (_status == OrderStatus.Delivered){
    //         o.deliveredAt = block.timestamp;
    //     }

    //     o.status = _status;
    //     emit OrderStatusUpdated(_orderId, _status);
    // }

    // Following functions are used to update order status. 
    // They had to be broken down to prevent status transition logic from breaking
    
    // Marks order as Paid. Can be called only by escrowContract when order is Created
    function markAsPaid(uint256 _orderId) public {

        // Retrieve order data
        Order storage o = orders[_orderId];

        // Validate sender, order, and previous status
        require(msg.sender == escrowContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Created, "Order status must be Created");

        o.status = OrderStatus.Paid;

        emit OrderStatusUpdated(_orderId, OrderStatus.Paid);
    }

    // Marks order as Shipped. Can only be called by deliveryContract when order is Paid
    function markAsShipped(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(msg.sender == deliveryContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.deliveryProvider != address(0), "Delivery provider must be assigned");
        require(o.status == OrderStatus.Paid, "Order status must be Paid");

        o.status = OrderStatus.Shipped;

        emit OrderStatusUpdated(_orderId, OrderStatus.Shipped);
    }

    // Marks order as InTransit. Can only be called by deliveryContract when order is Shipped
    function markAsInTransit(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(msg.sender == deliveryContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Shipped, "Order status must be Shipped");

        o.status = OrderStatus.InTransit;

        emit OrderStatusUpdated(_orderId, OrderStatus.InTransit);
    }

    // Marks order as Delivered. Can only be called by deliveryContract when order is InTransit
    function markAsDelivered(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(msg.sender == deliveryContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.InTransit, "Order status must be InTransit");

        o.status = OrderStatus.Delivered;

        // Record a timestamp of when order is delivered
        o.deliveredAt = block.timestamp;

        emit OrderStatusUpdated(_orderId, OrderStatus.Delivered);
    }

    // Marks order as Completed. Can only be called by escrowContract when order is Delivered
    function markAsCompleted(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(msg.sender == escrowContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Delivered, "Order status must be Delivered");

        o.status = OrderStatus.Completed;

        emit OrderStatusUpdated(_orderId, OrderStatus.Completed);
    }

    // Marks order as Failed. Can only be called by escrowContract, retailer and supplier, and 
    // if order is not Delivered, Completed or Refunded
    function markAsFailed(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(
            msg.sender == escrowContract ||
            msg.sender == o.retailer ||
            msg.sender == o.supplier,
            "Unauthorised"
        );
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(
            o.status != OrderStatus.Delivered &&
            o.status != OrderStatus.Completed &&
            o.status != OrderStatus.Refunded,
            "Order status must be Delivered, Completed or Refunded"
        );

        o.status = OrderStatus.Failed;

        emit OrderStatusUpdated(_orderId, OrderStatus.Failed);
    }

    // Marks order as Refunded. Can only be called by escrowContract when order is Failed
    function markAsRefunded(uint256 _orderId) public {
        Order storage o = orders[_orderId];

        require(msg.sender == escrowContract, "Unauthorised");
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.status == OrderStatus.Failed, "Order status must be Failed");

        o.status = OrderStatus.Refunded;

        emit OrderStatusUpdated(_orderId, OrderStatus.Refunded);
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