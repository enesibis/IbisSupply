const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer, account1, account2, account3, account4, account5, account6, account7] =
    await ethers.getSigners();

  console.log("=".repeat(60));
  console.log("IbisSupply — Deploy Scripti");
  console.log("=".repeat(60));
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  // -------------------------------------------------------------------------
  // 1. ProductRegistry
  // -------------------------------------------------------------------------
  console.log("\n📦 Deploying ProductRegistry...");
  const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
  const productRegistry = await ProductRegistry.deploy();
  await productRegistry.waitForDeployment();
  const registryAddr = await productRegistry.getAddress();
  console.log("✅ ProductRegistry deployed to:", registryAddr);

  // -------------------------------------------------------------------------
  // 2. SupplyChain
  // -------------------------------------------------------------------------
  console.log("\n🔗 Deploying SupplyChain...");
  const SupplyChain = await ethers.getContractFactory("SupplyChain");
  const supplyChain = await SupplyChain.deploy(registryAddr);
  await supplyChain.waitForDeployment();
  const supplyAddr = await supplyChain.getAddress();
  console.log("✅ SupplyChain deployed to:", supplyAddr);

  // -------------------------------------------------------------------------
  // 3. ConsumerQuery
  // -------------------------------------------------------------------------
  console.log("\n🔍 Deploying ConsumerQuery...");
  const ConsumerQuery = await ethers.getContractFactory("ConsumerQuery");
  const consumerQuery = await ConsumerQuery.deploy(registryAddr, supplyAddr);
  await consumerQuery.waitForDeployment();
  const queryAddr = await consumerQuery.getAddress();
  console.log("✅ ConsumerQuery deployed to:", queryAddr);

  // -------------------------------------------------------------------------
  // 4. RoleManager
  // -------------------------------------------------------------------------
  console.log("\n🔐 Deploying RoleManager...");
  const RoleManager = await ethers.getContractFactory("RoleManager");
  const roleManager = await RoleManager.deploy();
  await roleManager.waitForDeployment();
  const roleManagerAddr = await roleManager.getAddress();
  console.log("✅ RoleManager deployed to:", roleManagerAddr);

  // -------------------------------------------------------------------------
  // 5. Test rolleri ayarla (Hardhat local hesapları)
  // -------------------------------------------------------------------------
  console.log("\n👥 Test rolleri atanıyor...");

  // Role enum değerleri: NONE=0,CONSUMER=1,RETAILER=2,LOGISTICS=3,
  //                      WAREHOUSE=4,QUALITY_CONTROL=5,PROCESSOR=6,PRODUCER=7,ADMIN=8

  const roleAssignments = [
    { account: account1, role: 7, label: "PRODUCER",         name: "accounts[1]" },
    { account: account2, role: 6, label: "PROCESSOR",        name: "accounts[2]" },
    { account: account3, role: 5, label: "QUALITY_CONTROL",  name: "accounts[3]" },
    { account: account4, role: 4, label: "WAREHOUSE",        name: "accounts[4]" },
    { account: account5, role: 3, label: "LOGISTICS",        name: "accounts[5]" },
    { account: account6, role: 2, label: "RETAILER",         name: "accounts[6]" },
    { account: account7, role: 1, label: "CONSUMER",         name: "accounts[7]" },
  ];

  for (const { account, role, label, name } of roleAssignments) {
    if (!account) continue;
    await roleManager.grantRole(account.address, role);
    console.log(`  ✅ ${name} (${account.address.slice(0,10)}...) → ${label}`);
  }

  // ProductRegistry ve SupplyChain yetkilendirmeleri
  console.log("\n🔑 Sözleşme yetkilendirmeleri yapılıyor...");

  // PRODUCER hesabını ProductRegistry'e yetkilendir
  if (account1) {
    await productRegistry.authorizeProducer(account1.address);
    console.log("  ✅ accounts[1] (PRODUCER) → ProductRegistry'e yetkilendirildi");
  }

  // Tüm aktif hesapları SupplyChain'e yetkilendir
  const activeAccounts = [account1, account2, account3, account4, account5, account6].filter(Boolean);
  for (const acc of activeAccounts) {
    await supplyChain.authorizeActor(acc.address);
  }
  console.log(`  ✅ accounts[1-6] → SupplyChain'e yetkilendirildi`);

  // deployer (ADMIN) zaten ProductRegistry owner'ı, direkt yetki var
  // deployer'ı da SupplyChain'e yetkilendir
  await supplyChain.authorizeActor(deployer.address);
  console.log(`  ✅ accounts[0] (ADMIN/deployer) → SupplyChain'e yetkilendirildi`);

  // -------------------------------------------------------------------------
  // 6. Adresleri kaydet
  // -------------------------------------------------------------------------
  const network = await ethers.provider.getNetwork();
  const addresses = {
    ProductRegistry: registryAddr,
    SupplyChain:     supplyAddr,
    ConsumerQuery:   queryAddr,
    RoleManager:     roleManagerAddr,
    network:         network.name,
    chainId:         network.chainId.toString(),
    deployedAt:      new Date().toISOString(),
  };

  fs.writeFileSync(
    "./deployed-addresses.json",
    JSON.stringify(addresses, null, 2)
  );
  console.log("\n📄 Adresler deployed-addresses.json dosyasına kaydedildi");

  // -------------------------------------------------------------------------
  // 7. config.js otomatik güncelle
  // -------------------------------------------------------------------------
  const configPath = path.join(__dirname, "../frontend/config.js");
  if (fs.existsSync(configPath)) {
    let cfg = fs.readFileSync(configPath, "utf8");

    // ADDRESSES bloğunu yeni değerlerle değiştir
    cfg = cfg.replace(
      /ADDRESSES:\s*\{[\s\S]*?\},/,
      `ADDRESSES: {\n    ProductRegistry: "${registryAddr}",\n    SupplyChain:     "${supplyAddr}",\n    ConsumerQuery:   "${queryAddr}",\n    RoleManager:     "${roleManagerAddr}",\n  },`
    );

    fs.writeFileSync(configPath, cfg);
    console.log("✅ frontend/config.js adresleri otomatik güncellendi");
  }

  // -------------------------------------------------------------------------
  // Özet
  // -------------------------------------------------------------------------
  console.log("\n" + "=".repeat(60));
  console.log("DEPLOY ÖZETI");
  console.log("=".repeat(60));
  console.log("ProductRegistry :", registryAddr);
  console.log("SupplyChain     :", supplyAddr);
  console.log("ConsumerQuery   :", queryAddr);
  console.log("RoleManager     :", roleManagerAddr);
  console.log("\nTest Hesapları:");
  console.log("  [0] ADMIN     :", deployer.address);
  if (account1) console.log("  [1] PRODUCER  :", account1.address);
  if (account2) console.log("  [2] PROCESSOR :", account2.address);
  if (account3) console.log("  [3] QC        :", account3.address);
  if (account4) console.log("  [4] WAREHOUSE :", account4.address);
  if (account5) console.log("  [5] LOGISTICS :", account5.address);
  if (account6) console.log("  [6] RETAILER  :", account6.address);
  if (account7) console.log("  [7] CONSUMER  :", account7.address);
  console.log("=".repeat(60));
  console.log("\n🌐 Arayüz: http://localhost:3000/login.html");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
