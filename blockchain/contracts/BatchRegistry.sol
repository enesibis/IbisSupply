// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RoleManager.sol";

/**
 * @title BatchRegistry
 * @notice Records product batch creation and status changes on-chain
 */
contract BatchRegistry {
    RoleManager public roleManager;

    enum BatchStatus {
        CREATED,
        IN_TRANSIT,
        IN_WAREHOUSE,
        SOLD,
        RECALLED
    }

    struct BatchRecord {
        string batchCode;
        bytes32 dataHash;       // SHA-256 of off-chain batch data
        address createdBy;
        uint256 createdAt;
        BatchStatus status;
    }

    struct StatusEvent {
        BatchStatus status;
        address updatedBy;
        uint256 timestamp;
        string note;
    }

    mapping(string => BatchRecord) private batches;
    mapping(string => StatusEvent[]) private batchHistory;
    string[] private batchCodes;

    event BatchCreated(string indexed batchCode, bytes32 dataHash, address createdBy);
    event BatchStatusUpdated(string indexed batchCode, BatchStatus newStatus, address updatedBy);

    modifier onlyAuthorized() {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role >= 6, "BatchRegistry: producer or higher required"); // PROCESSOR=6, PRODUCER=7, ADMIN=8
        _;
    }

    modifier batchExists(string memory batchCode) {
        require(batches[batchCode].createdAt != 0, "Batch does not exist");
        _;
    }

    constructor(address _roleManager) {
        roleManager = RoleManager(_roleManager);
    }

    function createBatch(
        string memory batchCode,
        bytes32 dataHash
    ) external onlyAuthorized {
        require(batches[batchCode].createdAt == 0, "Batch already exists");

        batches[batchCode] = BatchRecord({
            batchCode: batchCode,
            dataHash: dataHash,
            createdBy: msg.sender,
            createdAt: block.timestamp,
            status: BatchStatus.CREATED
        });

        batchHistory[batchCode].push(StatusEvent({
            status: BatchStatus.CREATED,
            updatedBy: msg.sender,
            timestamp: block.timestamp,
            note: "Batch created"
        }));

        batchCodes.push(batchCode);
        emit BatchCreated(batchCode, dataHash, msg.sender);
    }

    function updateBatchStatus(
        string memory batchCode,
        BatchStatus newStatus,
        string memory note
    ) external batchExists(batchCode) {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role >= 3, "BatchRegistry: logistics or higher required"); // LOGISTICS=3

        batches[batchCode].status = newStatus;

        batchHistory[batchCode].push(StatusEvent({
            status: newStatus,
            updatedBy: msg.sender,
            timestamp: block.timestamp,
            note: note
        }));

        emit BatchStatusUpdated(batchCode, newStatus, msg.sender);
    }

    function getBatch(string memory batchCode)
        external
        view
        batchExists(batchCode)
        returns (BatchRecord memory)
    {
        return batches[batchCode];
    }

    function getBatchHistory(string memory batchCode)
        external
        view
        batchExists(batchCode)
        returns (StatusEvent[] memory)
    {
        return batchHistory[batchCode];
    }

    function getBatchCount() external view returns (uint256) {
        return batchCodes.length;
    }
}
