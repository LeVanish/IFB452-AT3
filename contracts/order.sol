// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TODO
// Change getOrderDetails so it returns whole tuple. In remix it is displayed poely, but it can still be displayed properly on front end
// Break down status updates in different functions
contract OrderContract {
    address public owner;
    mapping(address => bool) public retailers;
    // set after escrow is deployed
    address public escrowContract;
    // set after delivery is deployed
    address public deliveryContract;

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

    struct Order {
        uint256 orderId;
        address customer;
        address retailer;
        address supplier;
        address deliveryProvider;
        string productName;
        uint256 quantity;
        uint256 price;
        uint256 createdAt;
        uint256 deliveredAt;
        OrderStatus status;
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCount;

    event RetailerAdded(address retailer);
    event RetailerRemoved(address retailer);
    event OrderCreated(uint256 orderId, address customer, address retailer, address supplier, uint256 quantity, uint256 price);
    event OrderDetailsUpdated(uint256 orderId, string productName, uint256 quantity, uint256 price);
    event OrderStatusUpdated(uint256 orderId, OrderStatus status);

    constructor() {
        owner = msg.sender;
        retailers[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    modifier onlyRetailer() {
        require(retailers[msg.sender], "Only retailer can do this");
        _;
    }

    function addRetailer(address _retailer) public onlyOwner {
        require(_retailer != address(0), "Invalid address");

        retailers[_retailer] = true;
        emit RetailerAdded(_retailer);
    }
    
    function removeRetailer(address _retailer) public onlyOwner {
        require(_retailer != address(0), "Invalid address");

        retailers[_retailer] = false;
        emit RetailerRemoved(_retailer);
    }

    function setDeliveryProvider(uint256 _orderId, address _deliveryProvider) public {
        Order storage o = orders[_orderId];
        require(
            msg.sender == o.retailer ||
            msg.sender == o.supplier,
            "Not authorised to set delivery provider"
        );

        require(_deliveryProvider != address(0), "Provided address should be valid");

        o.deliveryProvider = _deliveryProvider;
    }   

    function setEscrowContract(address _escrowContract) public onlyOwner {
        escrowContract = _escrowContract;
    }

    function setDeliveryContract(address _deliveryContract) public onlyOwner {
        deliveryContract = _deliveryContract;
    }

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
        orders[orderCount] = Order(
            orderCount,
            _customer,
            msg.sender,
            _supplier,
            address(0),
            _productName,
            _quantity,
            _price,
            block.timestamp,
            0,
            OrderStatus.Created
        );
        emit OrderCreated(orderCount, _customer, msg.sender, _supplier, _quantity, _price);
    }

    function updateOrderDetails(
        uint256 _orderId,
        string memory _productName,
        uint256 _quantity,
        uint256 _price
    ) public {
        Order storage o = orders[_orderId];
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        require(o.retailer == msg.sender, "Unathorised sender");

        o.productName = _productName;
        o.quantity = _quantity;
        o.price = _price;
        emit OrderDetailsUpdated(_orderId, _productName, _quantity, _price);
    }

    //update status
    function updateOrderStatus(uint256 _orderId, OrderStatus _status) public {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        require(
            msg.sender == o.retailer ||
            msg.sender == o.supplier ||
            msg.sender == escrowContract ||
            msg.sender == deliveryContract,
            "Not authorised"
        );
        if (_status == OrderStatus.Delivered){
            o.deliveredAt = block.timestamp;
        }
        o.status = _status;
        emit OrderStatusUpdated(_orderId, _status);
    }

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

    function getOrderStatus(uint256 _orderId) public view returns (OrderStatus){
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        return orders[_orderId].status;
    }
}