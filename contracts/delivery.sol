// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TODO
// The customer should only be able to confirm delivery once delivery is completed
// Order status can be changed too easily, even when completed. We need to figure out some logic about when order status changes
// In order, Customer and Supplier addresses should not be empty
// The status should be displayed as a word (actually this is probably ok, displaying them on front end should still work)
// Payment distribution. By design we have payment split between retailer, supplier and delivery provider. Though what we have now is also ok and simpler
// In escrow contract, do we need getEcrowDetails? It seems to give the same info as "escrows" when contract is deployed
// In delivery contract, there should be some sort of modifier about who can update status.
// The escrow logic should be improved (refund on order fail, refund if order takes too long). This will require adding a Failed status to order

// Change getOrder to whole tuple

import "./Order.sol";

contract DeliveryTrackingContract {
    address public owner;
    OrderContract public orderContract;
    
    enum TrackingStatus{ Created, InTransit, Delivered, Failed }

    struct Tracking {
        uint256 orderId;

        uint256 createdTimestamp;
        address deliveryProvider;

        uint256 deliveredTimestamp;

        TrackingStatus status;
    }

    mapping(uint256 => Tracking) public trackings;
    
    event TrackingCreated(uint256 orderId, uint256 createdTimestamp, address deliveryProvider);
    event TrackingStatusUpdated(uint256 orderId, TrackingStatus status);
    event DeliveryCompleted(uint256 orderId, uint256 createdTimestamp, address deliveryProvider, uint256 deliveredTimestamp);
    
    constructor(address _orderContract) {
        owner = msg.sender;
        orderContract = OrderContract(_orderContract);  
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    modifier onlyDeliveryProvider(uint256 _orderId) {
        require(msg.sender == trackings[_orderId].deliveryProvider, "Only the delivery provder can do this");
        _;
    }

    function createTracking(uint256 _orderId) public onlyOwner {

        trackings[_orderId] = Tracking(
            _orderId,
            block.timestamp,
            owner,
            0,
            TrackingStatus.Created
        );

        Tracking storage t = trackings[_orderId];
        emit TrackingCreated(_orderId, t.createdTimestamp, t.deliveryProvider);
    }

    function updateTrackingStatus(uint256 _orderId, TrackingStatus _status) public onlyDeliveryProvider(_orderId) {

        Tracking storage t = trackings[_orderId];

        t.status = _status;
        if (_status == TrackingStatus.Delivered){
            t.deliveredTimestamp = block.timestamp;

            // Add order status update functionality
            emit DeliveryCompleted(_orderId, t.createdTimestamp, t.deliveryProvider, t.deliveredTimestamp);
            return;
        }

        // Add ecrow refund functionality for failed order

        emit TrackingStatusUpdated(_orderId, t.status);
    }
}