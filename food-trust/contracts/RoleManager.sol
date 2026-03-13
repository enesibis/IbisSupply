// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title RoleManager
 * @dev Rol tabanlı erişim kontrolü (RBAC) sözleşmesi.
 *      Her Ethereum adresine bir rol atanır; roller hiyerarşik değil, birbirinden bağımsızdır.
 *
 *  Roller (Role enum sırası):
 *   0 = NONE            – Tanımsız, sisteme erişim yok
 *   1 = CONSUMER        – Yalnızca ürün sorgulama
 *   2 = RETAILER        – Perakende olayı (tip 6)
 *   3 = LOGISTICS       – Sevkiyat / Teslim olayları (tip 4, 5)
 *   4 = WAREHOUSE       – Depolama olayı (tip 3)
 *   5 = QUALITY_CONTROL – Kalite kontrol olayı (tip 2)
 *   6 = PROCESSOR       – İşleme olayı (tip 1)
 *   7 = PRODUCER        – Ürün kaydı + hasat olayı (tip 0)
 *   8 = ADMIN           – Tam erişim + rol yönetimi
 */
contract RoleManager {

    // -----------------------------------------------------------------------
    // Tipler
    // -----------------------------------------------------------------------
    enum Role {
        NONE,           // 0
        CONSUMER,       // 1
        RETAILER,       // 2
        LOGISTICS,      // 3
        WAREHOUSE,      // 4
        QUALITY_CONTROL,// 5
        PROCESSOR,      // 6
        PRODUCER,       // 7
        ADMIN           // 8
    }

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    address public owner;
    mapping(address => Role) private _roles;
    address[] private _registeredUsers;
    mapping(address => bool) private _isRegistered;

    // -----------------------------------------------------------------------
    // Olaylar
    // -----------------------------------------------------------------------
    event RoleGranted(address indexed user, Role indexed role, address indexed grantedBy);
    event RoleRevoked(address indexed user, address indexed revokedBy);

    // -----------------------------------------------------------------------
    // Modifier
    // -----------------------------------------------------------------------
    modifier onlyAdmin() {
        require(_roles[msg.sender] == Role.ADMIN, "RoleManager: caller is not admin");
        _;
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------
    constructor() {
        owner = msg.sender;
        _roles[msg.sender] = Role.ADMIN;
        _register(msg.sender);
        emit RoleGranted(msg.sender, Role.ADMIN, msg.sender);
    }

    // -----------------------------------------------------------------------
    // Yönetim fonksiyonları (sadece ADMIN)
    // -----------------------------------------------------------------------

    /// @notice Bir adrese rol atar
    function grantRole(address user, Role role) external onlyAdmin {
        require(user != address(0), "Gecersiz adres");
        _roles[user] = role;
        _register(user);
        emit RoleGranted(user, role, msg.sender);
    }

    /// @notice Bir adresin rolünü kaldırır (NONE'a çeker)
    function revokeRole(address user) external onlyAdmin {
        require(user != owner, "Owner role cannot be revoked");
        _roles[user] = Role.NONE;
        emit RoleRevoked(user, msg.sender);
    }

    // -----------------------------------------------------------------------
    // Görünüm fonksiyonları
    // -----------------------------------------------------------------------

    /// @notice Adresin enum rol değerini döner
    function getRole(address user) external view returns (Role) {
        return _roles[user];
    }

    /// @notice Adresin rol numarasını (uint8) döner — frontend için
    function getRoleValue(address user) external view returns (uint8) {
        return uint8(_roles[user]);
    }

    /// @notice Adresin insan-okunur rol etiketini döner
    function getRoleLabel(address user) external view returns (string memory) {
        Role r = _roles[user];
        if (r == Role.ADMIN)            return "ADMIN";
        if (r == Role.PRODUCER)         return "PRODUCER";
        if (r == Role.PROCESSOR)        return "PROCESSOR";
        if (r == Role.QUALITY_CONTROL)  return "QUALITY_CONTROL";
        if (r == Role.WAREHOUSE)        return "WAREHOUSE";
        if (r == Role.LOGISTICS)        return "LOGISTICS";
        if (r == Role.RETAILER)         return "RETAILER";
        if (r == Role.CONSUMER)         return "CONSUMER";
        return "NONE";
    }

    /// @notice Kayıtlı tüm kullanıcıları ve rollerini döner
    function getAllUsers() external view returns (address[] memory users, uint8[] memory roles) {
        uint256 len = _registeredUsers.length;
        users = new address[](len);
        roles = new uint8[](len);
        for (uint256 i = 0; i < len; i++) {
            users[i] = _registeredUsers[i];
            roles[i] = uint8(_roles[_registeredUsers[i]]);
        }
    }

    /// @notice Toplam kayıtlı kullanıcı sayısı
    function getUserCount() external view returns (uint256) {
        return _registeredUsers.length;
    }

    // -----------------------------------------------------------------------
    // İç fonksiyonlar
    // -----------------------------------------------------------------------
    function _register(address user) internal {
        if (!_isRegistered[user]) {
            _isRegistered[user] = true;
            _registeredUsers.push(user);
        }
    }
}
