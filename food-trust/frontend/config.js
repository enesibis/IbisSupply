// Sözleşme adresleri ve ABI'ler
// deploy sonrası deployed-addresses.json ile güncellenir

const CONFIG = {
  NETWORK_NAME: "Localhost (Hardhat)",
  CHAIN_ID: 31337,
  RPC_URL: "http://127.0.0.1:8545",

  ADDRESSES: {
    ProductRegistry: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    SupplyChain:     "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    ConsumerQuery:   "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
    RoleManager:     "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
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
    ],

    RoleManager: [
      "function getRole(address user) view returns (uint8)",
      "function getRoleValue(address user) view returns (uint8)",
      "function getRoleLabel(address user) view returns (string)",
      "function grantRole(address user, uint8 role)",
      "function revokeRole(address user)",
      "function getAllUsers() view returns (address[] users, uint8[] roles)",
      "function getUserCount() view returns (uint256)",
      "function owner() view returns (address)",
      "event RoleGranted(address indexed user, uint8 indexed role, address indexed grantedBy)",
      "event RoleRevoked(address indexed user, address indexed revokedBy)"
    ]
  },

  // Rol sabitleri (RoleManager.Role enum ile eşleşir)
  ROLES: {
    NONE:            0,
    CONSUMER:        1,
    RETAILER:        2,
    LOGISTICS:       3,
    WAREHOUSE:       4,
    QUALITY_CONTROL: 5,
    PROCESSOR:       6,
    PRODUCER:        7,
    ADMIN:           8
  },

  // Türkçe rol etiketleri
  ROLE_LABELS: {
    0: "Tanımsız",
    1: "Tüketici",
    2: "Perakendeci",
    3: "Lojistik",
    4: "Depo Sorumlusu",
    5: "Kalite Kontrol",
    6: "İşleme Uzmanı",
    7: "Üretici",
    8: "Sistem Yöneticisi"
  },

  // Rol badge renkleri
  ROLE_COLORS: {
    0: "#64748b",
    1: "#6366f1",
    2: "#8b5cf6",
    3: "#f59e0b",
    4: "#3b82f6",
    5: "#ec4899",
    6: "#14b8a6",
    7: "#10b981",
    8: "#ef4444"
  },

  // Her rolün kaydedebileceği olay tipleri
  ROLE_ALLOWED_EVENTS: {
    0: [],
    1: [],
    2: [6],
    3: [4, 5],
    4: [3],
    5: [2],
    6: [1],
    7: [0],
    8: [0, 1, 2, 3, 4, 5, 6]
  },

  // Ürün kaydedebilen roller
  ROLES_CAN_REGISTER: [7, 8],

  // Admin paneline erişebilen roller
  ROLES_CAN_ACCESS_ADMIN: [2, 3, 4, 5, 6, 7, 8],

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
