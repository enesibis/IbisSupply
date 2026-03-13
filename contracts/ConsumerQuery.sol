// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ProductRegistry.sol";
import "./SupplyChain.sol";

/**
 * @title ConsumerQuery
 * @dev QR kod ile tüketicinin ürün geçmişini sorgulayabildiği salt-okunur arayüz
 *      Bu sözleşme doğrudan gas harcamaz (sadece view/pure fonksiyonlar)
 */
contract ConsumerQuery {
    ProductRegistry public productRegistry;
    SupplyChain public supplyChain;

    struct ProductReport {
        uint256 productId;
        string name;
        string batchNumber;
        string origin;
        address producer;
        uint256 productionDate;
        uint256 quantity;
        uint256 totalEvents;
        bool allQualityPassed;
        string currentLocation;
        uint256 lastUpdateTime;
    }

    constructor(address productRegistryAddress, address supplyChainAddress) {
        productRegistry = ProductRegistry(productRegistryAddress);
        supplyChain = SupplyChain(supplyChainAddress);
    }

    /**
     * @dev QR kod tarandığında çağrılan ana sorgu fonksiyonu
     *      productId -> tam izlenebilirlik raporu döner
     */
    function getFullReport(uint256 productId)
        external
        view
        returns (
            ProductReport memory report,
            SupplyChain.SupplyEvent[] memory history
        )
    {
        ProductRegistry.Product memory product = productRegistry.getProduct(productId);
        history = supplyChain.getProductHistory(productId);

        bool allPassed = true;
        string memory lastLocation = product.origin;
        uint256 lastTime = product.productionDate;

        for (uint256 i = 0; i < history.length; i++) {
            if (!history[i].qualityPassed) {
                allPassed = false;
            }
            if (history[i].timestamp > lastTime) {
                lastTime = history[i].timestamp;
                lastLocation = history[i].location;
            }
        }

        report = ProductReport({
            productId: product.id,
            name: product.name,
            batchNumber: product.batchNumber,
            origin: product.origin,
            producer: product.producer,
            productionDate: product.productionDate,
            quantity: product.quantity,
            totalEvents: history.length,
            allQualityPassed: allPassed,
            currentLocation: lastLocation,
            lastUpdateTime: lastTime
        });
    }

    /**
     * @dev Hızlı özet - sadece kritik bilgiler (düşük gas alternatifi)
     */
    function getQuickSummary(uint256 productId)
        external
        view
        returns (
            string memory name,
            string memory origin,
            uint256 totalSteps,
            bool isSafe,
            string memory currentLocation
        )
    {
        ProductRegistry.Product memory product = productRegistry.getProduct(productId);
        SupplyChain.SupplyEvent[] memory history = supplyChain.getProductHistory(productId);

        bool safe = true;
        string memory loc = product.origin;

        for (uint256 i = 0; i < history.length; i++) {
            if (!history[i].qualityPassed) safe = false;
            if (i == history.length - 1) loc = history[i].location;
        }

        return (product.name, product.origin, history.length, safe, loc);
    }
}
