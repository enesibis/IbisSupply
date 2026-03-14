// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RoleManager.sol";

/**
 * @title ShipmentRegistry
 * @notice Records shipment creation, events, and delivery on-chain
 */
contract ShipmentRegistry {
    RoleManager public roleManager;

    enum ShipmentStatus {
        PENDING,
        IN_TRANSIT,
        DELIVERED,
        FAILED
    }

    enum EventType {
        DEPARTED,
        CHECKPOINT,
        INCIDENT,
        DELIVERED
    }

    struct ShipmentRecord {
        string shipmentCode;
        string batchCode;
        bytes32 routeHash;      // hash of from+to locations
        address carrierId;
        uint256 createdAt;
        uint256 deliveredAt;
        ShipmentStatus status;
    }

    struct ShipmentEvent {
        EventType eventType;
        bytes32 dataHash;       // hash of location+temperature+notes
        address recordedBy;
        uint256 timestamp;
    }

    mapping(string => ShipmentRecord) private shipments;
    mapping(string => ShipmentEvent[]) private shipmentEvents;

    event ShipmentCreated(string indexed shipmentCode, string batchCode, address carrier);
    event ShipmentEventAdded(string indexed shipmentCode, EventType eventType);
    event ShipmentDelivered(string indexed shipmentCode, address receivedBy, uint256 timestamp);

    modifier onlyLogisticsOrHigher() {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role >= 3, "ShipmentRegistry: logistics or higher required");
        _;
    }

    modifier shipmentExists(string memory shipmentCode) {
        require(shipments[shipmentCode].createdAt != 0, "Shipment does not exist");
        _;
    }

    constructor(address _roleManager) {
        roleManager = RoleManager(_roleManager);
    }

    function createShipment(
        string memory shipmentCode,
        string memory batchCode,
        bytes32 routeHash
    ) external onlyLogisticsOrHigher {
        require(shipments[shipmentCode].createdAt == 0, "Shipment already exists");

        shipments[shipmentCode] = ShipmentRecord({
            shipmentCode: shipmentCode,
            batchCode: batchCode,
            routeHash: routeHash,
            carrierId: msg.sender,
            createdAt: block.timestamp,
            deliveredAt: 0,
            status: ShipmentStatus.PENDING
        });

        emit ShipmentCreated(shipmentCode, batchCode, msg.sender);
    }

    function addShipmentEvent(
        string memory shipmentCode,
        EventType eventType,
        bytes32 dataHash
    ) external onlyLogisticsOrHigher shipmentExists(shipmentCode) {
        shipmentEvents[shipmentCode].push(ShipmentEvent({
            eventType: eventType,
            dataHash: dataHash,
            recordedBy: msg.sender,
            timestamp: block.timestamp
        }));

        if (eventType == EventType.DEPARTED && shipments[shipmentCode].status == ShipmentStatus.PENDING) {
            shipments[shipmentCode].status = ShipmentStatus.IN_TRANSIT;
        }

        emit ShipmentEventAdded(shipmentCode, eventType);
    }

    function receiveShipment(
        string memory shipmentCode
    ) external shipmentExists(shipmentCode) {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role >= 2, "ShipmentRegistry: retailer or higher required"); // RETAILER=2, WAREHOUSE=4

        shipments[shipmentCode].status = ShipmentStatus.DELIVERED;
        shipments[shipmentCode].deliveredAt = block.timestamp;

        shipmentEvents[shipmentCode].push(ShipmentEvent({
            eventType: EventType.DELIVERED,
            dataHash: bytes32(0),
            recordedBy: msg.sender,
            timestamp: block.timestamp
        }));

        emit ShipmentDelivered(shipmentCode, msg.sender, block.timestamp);
    }

    function getShipment(string memory shipmentCode)
        external
        view
        shipmentExists(shipmentCode)
        returns (ShipmentRecord memory)
    {
        return shipments[shipmentCode];
    }

    function getShipmentEvents(string memory shipmentCode)
        external
        view
        shipmentExists(shipmentCode)
        returns (ShipmentEvent[] memory)
    {
        return shipmentEvents[shipmentCode];
    }
}
