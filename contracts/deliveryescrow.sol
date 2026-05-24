// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Order.sol";

contract DeliveryContract {
    address public owner;
    OrderContract public orderContract;

    event DeliveryStatusUpdated(uint256 orderId, address deliveryProvider, OrderContract.OrderStatus status);

    constructor(address _orderContract) {
        owner = msg.sender;
        orderContract = OrderContract(_orderContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    function updateDeliveryStatus(uint256 _orderId, OrderContract.OrderStatus _status) public onlyOwner {
        // Only certain statuses can be used to update order status
        require(
            _status == OrderContract.OrderStatus.Shipped ||
            _status == OrderContract.OrderStatus.InTransit ||
            _status == OrderContract.OrderStatus.Delivered ||
            _status == OrderContract.OrderStatus.Failed,
            "Cannot update to provided status"
        );

        OrderContract.OrderStatus ordStatus = orderContract.getOrderStatus(_orderId);
        require(
            ordStatus != 
        );

        orderContract.updateOrderStatus(_orderId, _status);

        emit DeliveryStatusUpdated(_orderId, msg.sender, _status);
    }
}