// Sözleşme adresleri ve ABI'ler
// deploy sonrası deployed-addresses.json ile güncellenir

const CONFIG = {
  NETWORK_NAME: "Localhost (Hardhat)",
  CHAIN_ID: 31337,

  ADDRESSES: {
    ProductRegistry: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    SupplyChain:     "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    ConsumerQuery:   "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  },

  ABI: {
    ProductRegistry: [
      "function registerProduct(string name, string batchNumber, string origin, uint256 productionDate, uint256 quantity) returns (uint256)",
      "function getProduct(uint256 productId) view returns (tuple(uint256 id, string name, string batchNumber, string origin, address producer, uint256 productionDate, uint256 quantity, bool isActive))",
      "function getTotalProducts() view returns (uint256)",
      "function authorizeProducer(address producer)",
      "function authorizedProducers(address) view returns (bool)",
      "function owner() view returns (address)",
      "event ProductRegistered(uint256 indexed productId, string name, string batchNumber, address indexed producer, uint256 productionDate)"
    ],

    SupplyChain: [
      "function recordEvent(uint256 productId, uint8 eventType, string actorName, string location, string notes, bool qualityPassed) returns (uint256)",
      "function getProductHistory(uint256 productId) view returns (tuple(uint256 eventId, uint256 productId, uint8 eventType, address actor, string actorName, string location, uint256 timestamp, string notes, bool qualityPassed)[])",
      "function authorizeActor(address actor)",
      "function authorizedActors(address) view returns (bool)",
      "function getTotalEvents() view returns (uint256)"
    ],

    ConsumerQuery: [
      "function getFullReport(uint256 productId) view returns (tuple(uint256 productId, string name, string batchNumber, string origin, address producer, uint256 productionDate, uint256 quantity, uint256 totalEvents, bool allQualityPassed, string currentLocation, uint256 lastUpdateTime), tuple(uint256 eventId, uint256 productId, uint8 eventType, address actor, string actorName, string location, uint256 timestamp, string notes, bool qualityPassed)[])",
      "function getQuickSummary(uint256 productId) view returns (string name, string origin, uint256 totalSteps, bool isSafe, string currentLocation)"
    ]
  },

  EVENT_TYPES: [
    "Hasat / Üretim",
    "İşleme",
    "Kalite Kontrolü",
    "Depolama",
    "Sevkiyat",
    "Teslim Alındı",
    "Perakende"
  ],

  EVENT_ICONS: ["🌿", "⚙️", "🔬", "🏭", "🚛", "📦", "🛒"]
};
