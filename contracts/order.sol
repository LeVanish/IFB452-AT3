// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OrderContract {
    address public owner;
    // set after Escrow is deployed
    address public escrowContract;

    enum OrderStatus { Created, Paid, Shipped, InTransit, Delivered, Completed }

    struct Order {
        uint256 orderId;
        address customer;
        address retailer;
        address supplier;
        string productName;
        string productDescription;
        uint256 price;
        OrderStatus status;
        // TODO: add createdat later for auto payment relese 
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCount;

    event OrderCreated(uint256 orderId, address customer, address retailer, address supplier, uint256 price);
    event OrderDetailsUpdated(uint256 orderId, string productName, uint256 price);
    event OrderStatusUpdated(uint256 orderId, OrderStatus status);

    constructor() {
        owner = msg.sender;
    }

    // only the retailer who created this order
    modifier onlyRetailer(uint256 _orderId) {
        require(msg.sender == orders[_orderId].retailer, "Only the retailer can do this");
        _;
    }

    
    function setEscrowContract(address _escrowContract) public {
        require(msg.sender == owner, "Only owner");
        escrowContract = _escrowContract;
    }

    function createOrder(
        address _customer,
        address _supplier,
        string memory _productName,
        string memory _productDescription,
        uint256 _price
    ) public {
        orderCount++;
        orders[orderCount] = Order(
            orderCount,
            _customer,
            msg.sender,
            _supplier,
            _productName,
            _productDescription,
            _price,
            OrderStatus.Created
        );
        emit OrderCreated(orderCount, _customer, msg.sender, _supplier, _price);
    }

    function updateOrderDetails(
        uint256 _orderId,
        string memory _productName,
        string memory _productDescription,
        uint256 _price
    ) public onlyRetailer(_orderId) {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        o.productName = _productName;
        o.productDescription = _productDescription;
        o.price = _price;
        emit OrderDetailsUpdated(_orderId, _productName, _price);
    }


    function updateOrderStatus(uint256 _orderId, OrderStatus _status) public {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        require(
            msg.sender == o.customer ||
            msg.sender == o.retailer ||
            msg.sender == o.supplier ||
            msg.sender == escrowContract,
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
            string memory productDescription,
            uint256 price,
            OrderStatus status
        )
    {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order ID");
        Order storage o = orders[_orderId];
        return (o.customer, o.retailer, o.supplier, o.productName, o.productDescription, o.price, o.status);
    }
}