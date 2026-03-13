// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ProductRegistry
 * @dev Gıda ürünlerini blok zincirine kaydeden sözleşme (Üretici Kaydı Modülü)
 */
contract ProductRegistry {
    // -----------------------------------------------------------------------
    // Tipler
    // -----------------------------------------------------------------------
    struct Product {
        uint256 id;
        string name;           // Ürün adı (Zeytinyağı vb.)
        string batchNumber;    // Parti/lot numarası
        string origin;         // Menşei (şehir/bölge)
        address producer;      // Üreticinin Ethereum adresi
        uint256 productionDate;// Unix timestamp
        uint256 quantity;      // kg / litre
        bool isActive;
    }

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    uint256 private _productCount;
    mapping(uint256 => Product) public products;
    mapping(address => bool) public authorizedProducers;
    address public owner;

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    event ProductRegistered(
        uint256 indexed productId,
        string name,
        string batchNumber,
        address indexed producer,
        uint256 productionDate
    );
    event ProducerAuthorized(address indexed producer);
    event ProducerRevoked(address indexed producer);

    // -----------------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyProducer() {
        require(authorizedProducers[msg.sender], "Not authorized producer");
        _;
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------
    constructor() {
        owner = msg.sender;
        authorizedProducers[msg.sender] = true;
    }

    // -----------------------------------------------------------------------
    // Owner fonksiyonları
    // -----------------------------------------------------------------------
    function authorizeProducer(address producer) external onlyOwner {
        authorizedProducers[producer] = true;
        emit ProducerAuthorized(producer);
    }

    function revokeProducer(address producer) external onlyOwner {
        authorizedProducers[producer] = false;
        emit ProducerRevoked(producer);
    }

    // -----------------------------------------------------------------------
    // Ana fonksiyonlar
    // -----------------------------------------------------------------------
    function registerProduct(
        string calldata name,
        string calldata batchNumber,
        string calldata origin,
        uint256 productionDate,
        uint256 quantity
    ) external onlyProducer returns (uint256) {
        _productCount++;
        uint256 newId = _productCount;

        products[newId] = Product({
            id: newId,
            name: name,
            batchNumber: batchNumber,
            origin: origin,
            producer: msg.sender,
            productionDate: productionDate,
            quantity: quantity,
            isActive: true
        });

        emit ProductRegistered(newId, name, batchNumber, msg.sender, productionDate);
        return newId;
    }

    function getProduct(uint256 productId) external view returns (Product memory) {
        require(products[productId].id != 0, "Product not found");
        return products[productId];
    }

    function getTotalProducts() external view returns (uint256) {
        return _productCount;
    }
}
