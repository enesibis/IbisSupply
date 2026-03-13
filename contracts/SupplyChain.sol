// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ProductRegistry.sol";

/**
 * @title SupplyChain
 * @dev Tedarik zinciri olaylarını (transfer, depolama, kontrol) kaydeden modül
 */
contract SupplyChain {
    // -----------------------------------------------------------------------
    // Tipler
    // -----------------------------------------------------------------------
    enum EventType {
        HARVESTED,      // 0 - Hasat / Üretim
        PROCESSED,      // 1 - İşleme
        QUALITY_CHECK,  // 2 - Kalite Kontrolü
        STORED,         // 3 - Depolama
        SHIPPED,        // 4 - Sevkiyat
        RECEIVED,       // 5 - Teslim Alındı
        RETAIL          // 6 - Perakende'ye ulaştı
    }

    struct SupplyEvent {
        uint256 eventId;
        uint256 productId;
        EventType eventType;
        address actor;          // İşlemi yapan kişi/kurum adresi
        string actorName;       // Okunabilir isim (Konya Deposu vb.)
        string location;        // GPS koordinat veya şehir
        uint256 timestamp;
        string notes;           // Sıcaklık, nem, açıklama
        bool qualityPassed;     // Kalite kontrolü geçti mi?
    }

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    uint256 private _eventCount;
    mapping(uint256 => SupplyEvent) public events;
    // productId => eventId listesi (izlenebilirlik haritası)
    mapping(uint256 => uint256[]) private _productEvents;

    ProductRegistry public productRegistry;
    address public owner;
    mapping(address => bool) public authorizedActors;

    // Akıllı Sözleşme Denetim Kuralları (ISO 22000 / Türk Gıda Kodeksi)
    int8 public constant MAX_TEMP_CELSIUS = 8;   // Soğuk zincir max sıcaklık
    uint256 public constant MAX_TRANSIT_HOURS = 72; // Max taşıma süresi (saat)

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    event SupplyEventRecorded(
        uint256 indexed eventId,
        uint256 indexed productId,
        EventType eventType,
        address indexed actor,
        uint256 timestamp
    );
    event QualityAlert(
        uint256 indexed productId,
        uint256 indexed eventId,
        string reason
    );

    // -----------------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyActor() {
        require(authorizedActors[msg.sender], "Not authorized actor");
        _;
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------
    constructor(address productRegistryAddress) {
        owner = msg.sender;
        productRegistry = ProductRegistry(productRegistryAddress);
        authorizedActors[msg.sender] = true;
    }

    // -----------------------------------------------------------------------
    // Yetki yönetimi
    // -----------------------------------------------------------------------
    function authorizeActor(address actor) external onlyOwner {
        authorizedActors[actor] = true;
    }

    function revokeActor(address actor) external onlyOwner {
        authorizedActors[actor] = false;
    }

    // -----------------------------------------------------------------------
    // Ana fonksiyonlar
    // -----------------------------------------------------------------------
    function recordEvent(
        uint256 productId,
        EventType eventType,
        string calldata actorName,
        string calldata location,
        string calldata notes,
        bool qualityPassed
    ) external onlyActor returns (uint256) {
        // Ürünün kayıtlı olduğunu doğrula
        ProductRegistry.Product memory product = productRegistry.getProduct(productId);
        require(product.isActive, "Product is not active");

        _eventCount++;
        uint256 newEventId = _eventCount;

        events[newEventId] = SupplyEvent({
            eventId: newEventId,
            productId: productId,
            eventType: eventType,
            actor: msg.sender,
            actorName: actorName,
            location: location,
            timestamp: block.timestamp,
            notes: notes,
            qualityPassed: qualityPassed
        });

        _productEvents[productId].push(newEventId);

        emit SupplyEventRecorded(newEventId, productId, eventType, msg.sender, block.timestamp);

        // Kalite kontrolü başarısızsa uyarı yayınla
        if (!qualityPassed) {
            emit QualityAlert(productId, newEventId, notes);
        }

        return newEventId;
    }

    // -----------------------------------------------------------------------
    // Sorgulama (Tüketici / İzleme Arayüzü)
    // -----------------------------------------------------------------------
    function getProductHistory(uint256 productId)
        external
        view
        returns (SupplyEvent[] memory)
    {
        uint256[] memory eventIds = _productEvents[productId];
        SupplyEvent[] memory history = new SupplyEvent[](eventIds.length);
        for (uint256 i = 0; i < eventIds.length; i++) {
            history[i] = events[eventIds[i]];
        }
        return history;
    }

    function getProductEventCount(uint256 productId) external view returns (uint256) {
        return _productEvents[productId].length;
    }

    function getTotalEvents() external view returns (uint256) {
        return _eventCount;
    }

    // -----------------------------------------------------------------------
    // Geri çağırma simülasyonu (Recall)
    // -----------------------------------------------------------------------
    function getAffectedBatch(uint256 productId)
        external
        view
        returns (
            ProductRegistry.Product memory product,
            SupplyEvent[] memory history
        )
    {
        product = productRegistry.getProduct(productId);
        uint256[] memory eventIds = _productEvents[productId];
        history = new SupplyEvent[](eventIds.length);
        for (uint256 i = 0; i < eventIds.length; i++) {
            history[i] = events[eventIds[i]];
        }
    }
}
