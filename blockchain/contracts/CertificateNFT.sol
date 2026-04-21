// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./RoleManager.sol";

/**
 * @title CertificateNFT
 * @notice ERC-721 sertifika tokeni — kalite kontrolden geçen her batch için mint edilir.
 */
contract CertificateNFT is ERC721 {
    RoleManager public roleManager;

    uint256 private _nextTokenId;

    struct CertInfo {
        string  batchCode;
        string  productName;
        string  certType;       // "QUALITY_PASS", "ORGANIC", "HACCP" vb.
        address mintedBy;
        uint256 mintedAt;
    }

    // tokenId → CertInfo
    mapping(uint256 => CertInfo) public certOf;
    // batchCode → tokenId (0 = yok)
    mapping(string => uint256)   public tokenOfBatch;

    event CertificateMinted(
        uint256 indexed tokenId,
        string  indexed batchCode,
        string  productName,
        string  certType,
        address mintedBy
    );

    modifier onlyInspectorOrAdmin() {
        uint8 role = roleManager.getRoleValue(msg.sender);
        require(role == 5 || role == 8, "CertificateNFT: inspector or admin required");
        _;
    }

    constructor(address _roleManager)
        ERC721("IbisSupply Certificate", "IBIS-CERT")
    {
        roleManager = RoleManager(_roleManager);
        _nextTokenId = 1;
    }

    /**
     * @notice Batch için sertifika NFT'si mint eder.
     * @param to         Token sahibi (denetçi/admin adresi)
     * @param batchCode  Batch kodu
     * @param productName Ürün adı
     * @param certType   Sertifika türü
     */
    function mintCertificate(
        address to,
        string memory batchCode,
        string memory productName,
        string memory certType
    ) external onlyInspectorOrAdmin returns (uint256) {
        require(tokenOfBatch[batchCode] == 0, "CertificateNFT: already minted for this batch");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        certOf[tokenId] = CertInfo({
            batchCode:   batchCode,
            productName: productName,
            certType:    certType,
            mintedBy:    msg.sender,
            mintedAt:    block.timestamp
        });
        tokenOfBatch[batchCode] = tokenId;

        emit CertificateMinted(tokenId, batchCode, productName, certType, msg.sender);
        return tokenId;
    }

    /**
     * @notice Batch koduna göre sertifika bilgisi döner.
     */
    function getCertByBatch(string memory batchCode)
        external
        view
        returns (uint256 tokenId, CertInfo memory info, bool exists)
    {
        tokenId = tokenOfBatch[batchCode];
        if (tokenId == 0) return (0, info, false);
        info   = certOf[tokenId];
        exists = true;
    }
}
