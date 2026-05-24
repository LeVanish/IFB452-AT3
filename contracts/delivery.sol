// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Order.sol";

/*
    Delivery Contract:

    - Allows delivery provider to update order status
    - Only certain statuses can be updated or assigned
*/

contract DeliveryContract {

    // Owner
    address public owner;

    // Used to link Delivery contract to Order contract
    OrderContract public orderContract;

    // Event for blockchain logs
    event DeliveryStatusUpdated(uint256 orderId, address deliveryProvider, OrderContract.OrderStatus status);

    constructor(address _orderContract) {
        owner = msg.sender;
        orderContract = OrderContract(_orderContract);
    }

    // Resticts access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    // Resticts access to order's delivery provider only
    modifier onlyDeliveryProvider(uint256 _orderId) {
        ( , , , address deliveryProvider, , , , , , ) = orderContract.getOrderDetails(_orderId);

        require(msg.sender == deliveryProvider, "Unauthorised");
        _;
    }

    // Mark order as Shipped. Can only be called by order's delivery provider
    function markAsShipped(uint256 _orderId) public onlyDeliveryProvider(_orderId){
        orderContract.markAsShipped(_orderId);
        emit DeliveryStatusUpdated(_orderId, msg.sender, OrderContract.OrderStatus.Shipped);
    }

    // Mark order as InTransit. Can only be called by order's delivery provider
    function markAsInTransit(uint256 _orderId) public onlyDeliveryProvider(_orderId){
        orderContract.markAsInTransit(_orderId);
        emit DeliveryStatusUpdated(_orderId, msg.sender, OrderContract.OrderStatus.InTransit);
    }

    // Mark order as Delivered. Can only be called by order's delivery provider
    function markAsDelivered(uint256 _orderId) public onlyDeliveryProvider(_orderId){
        orderContract.markAsDelivered(_orderId);
        emit DeliveryStatusUpdated(_orderId, msg.sender, OrderContract.OrderStatus.Delivered);
    }



    // // Lets assigned delivery provider to set order status
    // function updateDeliveryStatus(uint256 _orderId, OrderContract.OrderStatus _status) public {
    //     // Only delivery provider for this order may perform the action
    //     ( , , , address deliveryProvider, , , , , , ) = orderContract.getOrderDetails(_orderId);
    //     require(msg.sender == deliveryProvider, "Only the delivery provider can do this");

    //     // Only certain statuses can be used to update current status
    //     require(
    //         _status == OrderContract.OrderStatus.Shipped ||
    //         _status == OrderContract.OrderStatus.InTransit ||
    //         _status == OrderContract.OrderStatus.Delivered ||
    //         _status == OrderContract.OrderStatus.Failed,
    //         "Cannot update to provided status"
    //     );

    //     // Only certain statuses can be updated
    //     OrderContract.OrderStatus ordStatus = orderContract.getOrderStatus(_orderId);
    //     require(
    //         ordStatus != OrderContract.OrderStatus.Created &&
    //         ordStatus != OrderContract.OrderStatus.Delivered &&
    //         ordStatus != OrderContract.OrderStatus.Completed &&
    //         ordStatus != OrderContract.OrderStatus.Failed && 
    //         ordStatus != OrderContract.OrderStatus.Refunded,
    //         "Cannot update current order status"
    //     );

    //     orderContract.updateOrderStatus(_orderId, _status);

    //     emit DeliveryStatusUpdated(_orderId, msg.sender, _status);
    // }
}