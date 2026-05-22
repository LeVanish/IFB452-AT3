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

    function updateDeliveryStatus(uint256 _orderId, OrderContract.OrderStatus _status) public {
        require(
            _status == OrderContract.OrderStatus.InTransit ||
            _status == OrderContract.OrderStatus.Delivered,
            "Delivery can only update InTransit or Delivered conditions only"
        );

        orderContract.updateOrderStatus(_orderId, _status);

        emit DeliveryStatusUpdated(_orderId, msg.sender, _status);
    }
}