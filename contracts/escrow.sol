// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Order.sol";
// Customer deposits payment into escrow, pulls customer/retailer/price from the order, locks the funds and deposits when customer put dleovery as completed
contract EscrowContract {
    address public owner;
    OrderContract public orderContract;   
//TODO: add arbiter logic is time allows
    enum EscrowStatus {
        None,
        Deposited,
        Released
    }

    struct Escrow {
        uint256 orderId;
        address payable customer;
        address payable retailer;
        uint256 amount;
        bool deliveryConfirmed;
        EscrowStatus status;
    }

    mapping(uint256 => Escrow) public escrows;

    event PaymentDeposited(uint256 orderId, address customer, uint256 amount);
    event DeliveryConfirmed(uint256 orderId, bool DeliveryConfirmed);
    event FundsReleased(uint256 orderId, address retailer, uint256 amount);

    constructor(address _orderContract) {
        owner = msg.sender;
        orderContract = OrderContract(_orderContract);  
    }

    function depositPayment(uint256 _orderId) public payable {
        (
            address customer,
            address retailer,
            ,
            ,
            ,
            uint256 price,
            ,
            ,
            
        ) = orderContract.getOrderDetails(_orderId);

        require(msg.sender == customer, "Only the customer can deposit");
        require(escrows[_orderId].status == EscrowStatus.None, "Payment already deposited");
        require(msg.value == price, "Incorrect payment amount");

        escrows[_orderId] = Escrow(
            _orderId,
            payable(customer),
            payable(retailer),
            msg.value,
            false,
            EscrowStatus.Deposited
        );

     
        orderContract.updateOrderStatus(_orderId, OrderContract.OrderStatus.Paid);

        emit PaymentDeposited(_orderId, customer, msg.value);
    }

    // Customer confirms they received the delivery and Completed and releases funds to the retailer
    function confirmDelivery(uint256 _orderId) public {

        Escrow storage e = escrows[_orderId];
        require(orderContract.getOrderStatus(_orderId) == OrderContract.OrderStatus.Delivered, "Delivery is not completed yet");
        require(e.status == EscrowStatus.Deposited, "No deposited funds");
        require(msg.sender == e.customer, "Only the customer can confirm delivery");

        e.deliveryConfirmed = true;

        emit DeliveryConfirmed(_orderId, e.deliveryConfirmed);
    }

    function releaseFunds(uint256 _orderId) public {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 deliveredAt,
            
        ) = orderContract.getOrderDetails(_orderId);
        
        Escrow storage e = escrows[_orderId];

        require(e.status == EscrowStatus.Deposited, "No deposited funds");
        require(orderContract.getOrderStatus(_orderId) == OrderContract.OrderStatus.Delivered, "Delivery is not completed yet");

        bool confirmed = e.deliveryConfirmed;

        // The funds are released if either delivery is confirmed, or customer does not confirm delivery in 3 days
        require(
            confirmed ||
            block.timestamp >= deliveredAt + 3 days, 
            "Funds release conditions has not been met"
        );

        uint256 amount = e.amount;

        e.amount = 0;
        e.status = EscrowStatus.Released;
        orderContract.updateOrderStatus(_orderId, OrderContract.OrderStatus.Completed);

        (bool success, ) = e.retailer.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsReleased(_orderId, e.retailer, amount);
    }
    
    function refund(uint256 _orderId) public {
        Escrow storage e = escrows[_orderId];
        require(e.status == EscrowStatus.Deposited, "No deposited funds");

        // TODO: add refund confitions (order delivery time exceeded)
        uint256 amount = e.amount;

        e.amount = 0;
        e.status = EscrowStatus.Released;
        orderContract.updateOrderStatus(_orderId, OrderContract.OrderStatus.Completed);


        (bool success, ) = e.customer.call{value: amount}("");
        require(success, "Transfer failed");
    }

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