// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RoleManager.sol";

/**
 * @title FarmRegistry
 * @notice Records agricultural phase data (pesticides, irrigation, fertilizers) on-chain.
 *         Full details are stored off-chain; only a SHA-256 hash is written here for integrity.
 */
contract FarmRegistry {
    RoleManager public roleManager;

    struct FarmRecord {
        string  batchCode;
        bytes32 dataHash;       // SHA-256 of off-chain farm record data
        address recordedBy;
        uint256 timestamp;
    }

    // batchCode => list of farm records (a batch may have multiple applications)
    mapping(string => FarmRecord[]) private farmRecords;

    event FarmRecordAdded(
        string indexed batchCode,
        bytes32 dataHash,
        address recordedBy,
        uint256 timestamp
    );

    modifier onlyProducer() {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role >= 7, "FarmRegistry: producer or admin required"); // PRODUCER=7, ADMIN=8
        _;
    }

    constructor(address _roleManager) {
        roleManager = RoleManager(_roleManager);
    }

    /**
     * @notice Records a new farm data entry for a batch.
     * @param batchCode  The batch code this record belongs to.
     * @param dataHash   SHA-256 hash of the full farm data stored off-chain.
     */
    function recordFarmData(
        string memory batchCode,
        bytes32 dataHash
    ) external onlyProducer {
        require(bytes(batchCode).length > 0, "FarmRegistry: batchCode required");

        farmRecords[batchCode].push(FarmRecord({
            batchCode:  batchCode,
            dataHash:   dataHash,
            recordedBy: msg.sender,
            timestamp:  block.timestamp
        }));

        emit FarmRecordAdded(batchCode, dataHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Returns all farm records for a given batch.
     */
    function getFarmRecords(string memory batchCode)
        external
        view
        returns (FarmRecord[] memory)
    {
        return farmRecords[batchCode];
    }

    /**
     * @notice Returns the number of farm records for a batch.
     */
    function getFarmRecordCount(string memory batchCode)
        external
        view
        returns (uint256)
    {
        return farmRecords[batchCode].length;
    }
}
