/**
 * auth.js — IbisSupply Kimlik Doğrulama & Yetki Modülü
 *
 * Tüm sayfalar bu dosyayı yükler (config.js'den sonra).
 * Kullanım:
 *   const session = await AUTH.init();          // Bağlan + rolü oku
 *   AUTH.guardPage([ADMIN, PRODUCER]);           // Yetkisizse yönlendir
 *   AUTH.renderRoleBadge("container-id");        // Rol rozeti göster
 */

const AUTH = (() => {

  // -------------------------------------------------------------------------
  // Sabitler
  // -------------------------------------------------------------------------
  const SESSION_KEY = "ibissupply_session";
  const SESSION_TTL = 3600 * 1000; // 1 saat

  // -------------------------------------------------------------------------
  // Yardımcı: sessionStorage
  // -------------------------------------------------------------------------
  function saveSession(data) {
    sessionStorage.setItem(SESSION_KEY, JSON.stringify({
      ...data,
      savedAt: Date.now()
    }));
  }

  function loadSession() {
    try {
      const raw = sessionStorage.getItem(SESSION_KEY);
      if (!raw) return null;
      const data = JSON.parse(raw);
      if (Date.now() - data.savedAt > SESSION_TTL) {
        sessionStorage.removeItem(SESSION_KEY);
        return null;
      }
      return data;
    } catch (_) { return null; }
  }

  function clearSession() {
    sessionStorage.removeItem(SESSION_KEY);
  }

  // -------------------------------------------------------------------------
  // Ana init — MetaMask bağlantısı + rol sorgusu
  // -------------------------------------------------------------------------
  async function init() {
    if (!window.ethereum) return null;

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);

      // Hesap zaten bağlı mı kontrol et (kullanıcıya tekrar sormadan)
      const accounts = await provider.listAccounts();
      if (accounts.length === 0) return null;

      const signer  = await provider.getSigner();
      const address = await signer.getAddress();

      // Önce cache'e bak
      const cached = loadSession();
      if (cached && cached.address.toLowerCase() === address.toLowerCase()) {
        return { ...cached, provider, signer };
      }

      // Ağ kontrolü
      const network = await provider.getNetwork();
      if (Number(network.chainId) !== CONFIG.CHAIN_ID) {
        throw new Error(`Yanlış ağ! MetaMask'ta "Localhost 8545" (Chain 31337) seçin. Şu an: Chain ${network.chainId}`);
      }

      // RoleManager sözleşmesinden rolü oku
      const roleContract = new ethers.Contract(
        CONFIG.ADDRESSES.RoleManager,
        CONFIG.ABI.RoleManager,
        provider
      );
      const roleValue = Number(await roleContract.getRoleValue(address));

      const session = {
        address,
        role:      roleValue,
        roleLabel: CONFIG.ROLE_LABELS[roleValue] || "Tanımsız",
        chainId:   Number(network.chainId)
      };

      saveSession(session);
      return { ...session, provider, signer };

    } catch (_) { return null; }
  }

  // -------------------------------------------------------------------------
  // connectWallet — kullanıcı buton tıklaması ile çağırır
  // -------------------------------------------------------------------------
  async function switchToHardhat() {
    const chainHex = "0x" + CONFIG.CHAIN_ID.toString(16); // 0x7a69
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: chainHex }]
      });
    } catch (err) {
      // Ağ MetaMask'ta kayıtlı değilse ekle
      if (err.code === 4902) {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [{
            chainId: chainHex,
            chainName: "Hardhat Local",
            rpcUrls: ["http://127.0.0.1:8545"],
            nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 }
          }]
        });
      } else {
        throw err;
      }
    }
  }

  async function connectWallet() {
    if (!window.ethereum) throw new Error("MetaMask bulunamadı. Lütfen MetaMask yükleyin.");

    // Önce hesap bağlantısı iste
    await window.ethereum.request({ method: "eth_requestAccounts" });

    // Gerekirse ağı otomatik değiştir
    const currentChain = Number(await window.ethereum.request({ method: "eth_chainId" }));
    if (currentChain !== CONFIG.CHAIN_ID) {
      await switchToHardhat();
      // Ağ geçişi sonrası provider yeniden oluşturulmalı
    }

    // Provider ve signer'ı ağ geçişinden SONRA oluştur
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer   = await provider.getSigner();
    const address  = await signer.getAddress();
    const chainId  = Number((await provider.getNetwork()).chainId);

    const roleContract = new ethers.Contract(
      CONFIG.ADDRESSES.RoleManager,
      CONFIG.ABI.RoleManager,
      provider
    );
    const roleValue = Number(await roleContract.getRoleValue(address));

    const session = {
      address,
      role:      roleValue,
      roleLabel: CONFIG.ROLE_LABELS[roleValue] || "Tanımsız",
      chainId
    };

    saveSession(session);
    return { ...session, provider, signer };
  }

  // -------------------------------------------------------------------------
  // guardPage — izin verilmeyen rolle erişimi engelle
  // -------------------------------------------------------------------------
  function guardPage(allowedRoles, redirectTo = "login.html") {
    const session = loadSession();
    if (!session) {
      window.location.replace(redirectTo);
      return false;
    }
    if (!allowedRoles.includes(session.role)) {
      const suffix = session.role === CONFIG.ROLES.NONE ? "?err=noaccess" : "";
      window.location.replace(redirectTo + suffix);
      return false;
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // logout
  // -------------------------------------------------------------------------
  function logout() {
    clearSession();
    window.location.replace("login.html");
  }

  // -------------------------------------------------------------------------
  // renderRoleBadge — header/sidebar'a rol rozeti ekler
  // -------------------------------------------------------------------------
  function renderRoleBadge(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const session = loadSession();
    if (!session) return;

    const color = CONFIG.ROLE_COLORS[session.role] || "#64748b";
    const label = CONFIG.ROLE_LABELS[session.role] || "?";
    const addr  = session.address.slice(0, 8) + "..." + session.address.slice(-6);

    container.innerHTML = `
      <div class="auth-badge">
        <div class="auth-badge-role" style="background:${color}22;border-color:${color}55;color:${color}">
          ${label}
        </div>
        <div class="auth-badge-addr">${addr}</div>
        <button class="auth-badge-logout" onclick="AUTH.logout()" title="Çıkış Yap">⏻</button>
      </div>`;
  }

  // -------------------------------------------------------------------------
  // renderUserTable — ADMIN paneli için kullanıcı listesi
  // -------------------------------------------------------------------------
  async function renderUserTable(containerId, provider) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const roleContract = new ethers.Contract(
      CONFIG.ADDRESSES.RoleManager,
      CONFIG.ABI.RoleManager,
      provider
    );

    const [users, roles] = await roleContract.getAllUsers();

    if (users.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="icon">👥</div><div>Kayıtlı kullanıcı yok.</div></div>`;
      return;
    }

    let rows = "";
    for (let i = 0; i < users.length; i++) {
      const roleVal   = Number(roles[i]);
      const roleLabel = CONFIG.ROLE_LABELS[roleVal] || "?";
      const color     = CONFIG.ROLE_COLORS[roleVal] || "#64748b";
      const addr      = users[i];
      rows += `
        <tr>
          <td class="mono-sm">${addr}</td>
          <td>
            <span class="role-badge" style="background:${color}22;border-color:${color}55;color:${color}">
              ${roleLabel}
            </span>
          </td>
          <td>${roleVal === 0 ? '<span style="color:#64748b">—</span>' : `<button class="btn-revoke" onclick="revokeUserRole('${addr}')">Kaldır</button>`}</td>
        </tr>`;
    }

    container.innerHTML = `
      <table class="user-table">
        <thead>
          <tr><th>Adres</th><th>Rol</th><th>İşlem</th></tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>`;
  }

  // -------------------------------------------------------------------------
  // getSession — mevcut session'ı döner (async değil)
  // -------------------------------------------------------------------------
  function getSession() {
    return loadSession();
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------
  return {
    init,
    connectWallet,
    guardPage,
    logout,
    renderRoleBadge,
    renderUserTable,
    getSession,
    clearSession
  };

})();
