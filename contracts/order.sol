// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OrderContract {
    address public owner;
    // set after escrow is deployed
    address public escrowContract;
    // set after delivery is deployed
    address public deliveryContract;

    enum OrderStatus { Created, Paid, Shipped, InTransit, Delivered, Completed }

    struct Order {
        uint256 orderId;
        address customer;
        address retailer;
        address supplier;
        string productName;
        uint256 quantity;
        uint256 price;
        OrderStatus status;
        // TODO: add createdAt later for auto payment release
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCount;

    event OrderCreated(uint256 orderId, address customer, address retailer, address supplier, uint256 quantity, uint256 price);
    event OrderDetailsUpdated(uint256 orderId, string productName, uint256 quantity, uint256 price);
    event OrderStatusUpdated(uint256 orderId, OrderStatus status);

    constructor() {
        owner = msg.sender;
    }

    // Only the deployer can do this. Deployer is the retailer
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
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
    ) public onlyOwner {
        require(
            _customer != address(0) &&
            _supplier != address(0),
            "All adresses should be valid"
        );

        orderCount++;
        orders[orderCount] = Order(
            orderCount,
            _customer,
            msg.sender,
            _supplier,
            _productName,
            _quantity,
            _price,
            OrderStatus.Created
        );
        emit OrderCreated(orderCount, _customer, msg.sender, _supplier, _quantity, _price);
    }

    function updateOrderDetails(
        uint256 _orderId,
        string memory _productName,
        uint256 _quantity,
        uint256 _price
    ) public onlyOwner {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
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
            msg.sender == owner ||
            msg.sender == o.supplier ||
            msg.sender == escrowContract ||
            msg.sender == deliveryContract,
            "Not authorised"
        );
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
            string memory productName,
            uint256 quantity,
            uint256 price,
            OrderStatus status
        )
    {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        return (o.customer, o.retailer, o.supplier, o.productName, o.quantity, o.price, o.status);
    }
}