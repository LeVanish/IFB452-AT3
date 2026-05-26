// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./order.sol";

//TODO: add arbiter logic if time allows

/*
    Escrow Contract:

    - Securely stores customer's funds
    - Allows customer to confirm delivery of the product
    - Releases funds when delivery is confirmed or if order has been delivered for 3 days
    - Refunds to customer if order is failed or takes too long to be delivered
*/
contract EscrowContract {
    address public owner;

    // Used to link Escrow contract to Order contract
    OrderContract public orderContract;   

    // Escrow statuses to track escrow lifecycle
    enum EscrowStatus {
        None,
        Deposited,
        Released
    }

    // Escrow information    
    struct Escrow {
        uint256 orderId;

        // Relevant stakeholder addresses
        address payable customer;
        address payable retailer;

        // Price of the order in wei
        uint256 amount;

        // Boolean that tracks if delivery has been confirmed
        bool deliveryConfirmed;

        // Escrow status
        EscrowStatus status;
    }

    // Mapping: orderId => Escrow 
    mapping(uint256 => Escrow) public escrows;

    // Events for blockchain logs
    event PaymentDeposited(uint256 orderId, address customer, uint256 amount);
    event DeliveryConfirmed(uint256 orderId, bool deliveryConfirmed);
    event FundsReleased(uint256 orderId, address retailer, uint256 amount);
    event Refunded(uint256 orderId, address customer, uint256 amount);


    constructor(address _orderContract) {
        owner = msg.sender;
        orderContract = OrderContract(_orderContract);  
    }

    // Used by customer to deposit payment in the escrow
    function depositPayment(uint256 _orderId) public payable {
        
        // Retrieve relevant order information
        (address customer, address retailer, , , , , uint256 price, , , ) = orderContract.getOrderDetails(_orderId);

        // Verify sender, escrow status and correct amount
        require(msg.sender == customer, "Only the customer can deposit");
        require(escrows[_orderId].status == EscrowStatus.None, "Payment already deposited");
        require(msg.value == price, "Incorrect payment amount");

        // Creaye and store new escrow
        escrows[_orderId] = Escrow(
            _orderId,
            payable(customer),
            payable(retailer),
            msg.value,
            false,
            EscrowStatus.Deposited
        );

        // Update escrow status to Paid
        orderContract.markAsPaid(_orderId);

        emit PaymentDeposited(_orderId, customer, msg.value);
    }


    // Used by customer to confirm the delivery
    function confirmDelivery(uint256 _orderId) public {

        // Retrieve escrow data
        Escrow storage e = escrows[_orderId];

        // Check sender, delivery status, and if funds are deposited
        require(msg.sender == e.customer, "Only the customer can confirm delivery");
        require(orderContract.getOrderStatus(_orderId) == OrderContract.OrderStatus.Delivered, "Delivery is not completed yet");
        require(e.status == EscrowStatus.Deposited, "No deposited funds");
        
        // Set deliveryConfirmed to true
        e.deliveryConfirmed = true;

        emit DeliveryConfirmed(_orderId, e.deliveryConfirmed);
    }

    // Used to release funds if conditions are met. Anyone can call it by design
    function releaseFunds(uint256 _orderId) public {
        // Retrieve relevant order data
        ( , , , , , , , , uint256 deliveredAt, ) = orderContract.getOrderDetails(_orderId);
        
        // Retrieve escrow data
        Escrow storage e = escrows[_orderId];

        // Verify order status and if funds are deposited
        require(e.status == EscrowStatus.Deposited, "No deposited funds");
        require(orderContract.getOrderStatus(_orderId) == OrderContract.OrderStatus.Delivered, "Delivery is not completed");

        bool confirmed = e.deliveryConfirmed;

        // The funds are released if either delivery is confirmed, or customer does not confirm delivery in 3 days
        require(
            confirmed ||
            block.timestamp >= deliveredAt + 3 days, 
            "Funds release conditions have not been met"
        );


        // Set escrow amount to 0, status to Released, and order status to Completed
        uint256 amount = e.amount;
        e.amount = 0;
        e.status = EscrowStatus.Released;
        orderContract.markAsCompleted(_orderId);

        // Release the funds to the retailer
        (bool success, ) = e.retailer.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsReleased(_orderId, e.retailer, amount);
    }
    
    // Used to refund the deposit to the customer if conditions are met. Anyone can call it by design
    function refund(uint256 _orderId) public {
        
        // Retrieve relevant order data
        ( , , , , , , , uint256 createdAt, , OrderContract.OrderStatus status) = orderContract.getOrderDetails(_orderId);

        // Retrieve escrow data
        Escrow storage e = escrows[_orderId];

        // Verify the funds are deposited
        require(e.status == EscrowStatus.Deposited, "No deposited funds");

        // Check if order is expired or Failed
        bool expired = block.timestamp >= createdAt + 45 days;
        require(
            expired ||
            status == OrderContract.OrderStatus.Failed, 
            "Refund conditions are not met"
        );

        // Set escrow amount to 0, status to Released, and order status to Refunded
        uint256 amount = e.amount;
        e.amount = 0;
        e.status = EscrowStatus.Released;
        orderContract.markAsRefunded(_orderId);

        // Release the funds to the customer
        (bool success, ) = e.customer.call{value: amount}("");
        require(success, "Transfer failed");

        emit Refunded(_orderId, e.customer, amount);
    }

    // Used to retrieve escrow data
    function getEscrowDetails(uint256 _orderId)
        public
        view
        returns (
            address customer,
            address retailer,
            uint256 amount,
            EscrowStatus status
        )
    {
        Escrow storage e = escrows[_orderId];
        return (e.customer, e.retailer, e.amount, e.status);
    }

    // Used to receive escrow balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        revert("Use depositPayment");
    }

    fallback() external payable {
        revert("Invalid function");
    }
}