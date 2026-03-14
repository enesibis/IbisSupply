// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RoleManager.sol";

/**
 * @title QualityRegistry
 * @notice Records quality checks and certificates on-chain
 */
contract QualityRegistry {
    RoleManager public roleManager;

    enum QualityResult {
        PENDING,
        PASSED,
        FAILED,
        MARGINAL
    }

    struct QualityCheck {
        string batchCode;
        bytes32 dataHash;       // hash of full quality check data
        address inspectorId;
        QualityResult result;
        uint256 timestamp;
    }

    struct Certificate {
        string batchCode;
        string certType;        // "ORGANIC", "HALAL", "ISO", "HACCP"
        bytes32 issuerHash;     // hash of issuer info
        uint256 issueDate;
        uint256 expiryDate;
        address verifiedBy;
    }

    mapping(string => QualityCheck[]) private qualityChecks;
    mapping(string => Certificate[]) private certificates;

    event QualityCheckAdded(string indexed batchCode, QualityResult result, address inspector);
    event CertificateAdded(string indexed batchCode, string certType, address verifiedBy);

    modifier onlyInspector() {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role == 5 || role == 8, "QualityRegistry: inspector or admin required"); // INSPECTOR=5, ADMIN=8
        _;
    }

    constructor(address _roleManager) {
        roleManager = RoleManager(_roleManager);
    }

    function addQualityCheck(
        string memory batchCode,
        bytes32 dataHash,
        QualityResult result
    ) external onlyInspector {
        qualityChecks[batchCode].push(QualityCheck({
            batchCode: batchCode,
            dataHash: dataHash,
            inspectorId: msg.sender,
            result: result,
            timestamp: block.timestamp
        }));

        emit QualityCheckAdded(batchCode, result, msg.sender);
    }

    function verifyCertificate(
        string memory batchCode,
        string memory certType,
        bytes32 issuerHash,
        uint256 expiryDate
    ) external onlyInspector {
        certificates[batchCode].push(Certificate({
            batchCode: batchCode,
            certType: certType,
            issuerHash: issuerHash,
            issueDate: block.timestamp,
            expiryDate: expiryDate,
            verifiedBy: msg.sender
        }));

        emit CertificateAdded(batchCode, certType, msg.sender);
    }

    function getQualityChecks(string memory batchCode)
        external
        view
        returns (QualityCheck[] memory)
    {
        return qualityChecks[batchCode];
    }

    function getCertificates(string memory batchCode)
        external
        view
        returns (Certificate[] memory)
    {
        return certificates[batchCode];
    }

    function isActiveCertificate(string memory batchCode, string memory certType)
        external
        view
        returns (bool)
    {
        Certificate[] memory certs = certificates[batchCode];
        for (uint i = 0; i < certs.length; i++) {
            if (
                keccak256(bytes(certs[i].certType)) == keccak256(bytes(certType)) &&
                certs[i].expiryDate > block.timestamp
            ) {
                return true;
            }
        }
        return false;
    }
}
