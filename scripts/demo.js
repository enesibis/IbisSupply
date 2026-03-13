/**
 * demo.js - Zeytinyağı tedarik zinciri demo senaryosu
 * Çalıştır: npx hardhat run scripts/demo.js --network localhost
 */
const { ethers } = require("hardhat");

async function main() {
  const [owner, producer, logistics, retailer] = await ethers.getSigners();

  console.log("=".repeat(60));
  console.log("🫒  FOOD TRUST - Zeytinyağı Tedarik Zinciri Demo");
  console.log("=".repeat(60));

  // Sözleşmeleri yükle (deployed-addresses.json'dan)
  const addresses = require("../deployed-addresses.json");

  const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
  const SupplyChain = await ethers.getContractFactory("SupplyChain");
  const ConsumerQuery = await ethers.getContractFactory("ConsumerQuery");

  const registry = ProductRegistry.attach(addresses.ProductRegistry);
  const supply = SupplyChain.attach(addresses.SupplyChain);
  const query = ConsumerQuery.attach(addresses.ConsumerQuery);

  // -----------------------------------------------------------------------
  // ADIM 1: Üreticiyi yetkilendir
  // -----------------------------------------------------------------------
  console.log("\n[1] Üretici yetkilendiriliyor...");
  await registry.connect(owner).authorizeProducer(producer.address);
  await supply.connect(owner).authorizeActor(producer.address);
  await supply.connect(owner).authorizeActor(logistics.address);
  await supply.connect(owner).authorizeActor(retailer.address);
  console.log("✅ Üretici & aktörler yetkilendirildi");

  // -----------------------------------------------------------------------
  // ADIM 2: Ürün kaydı
  // -----------------------------------------------------------------------
  console.log("\n[2] Ürün blok zincirine kaydediliyor...");
  const now = Math.floor(Date.now() / 1000);
  const tx1 = await registry.connect(producer).registerProduct(
    "Natürel Sızma Zeytinyağı",
    "ZY-2025-001",
    "Ayvalık, Balıkesir",
    now,
    500  // 500 litre
  );
  const receipt1 = await tx1.wait();
  const productId = 1n;
  console.log("✅ Ürün kayıtlandı | ID:", productId.toString(), "| Tx:", receipt1.hash.slice(0, 16) + "...");

  // -----------------------------------------------------------------------
  // ADIM 3: Tedarik zinciri olayları
  // -----------------------------------------------------------------------
  const EventType = { HARVESTED: 0, PROCESSED: 1, QUALITY_CHECK: 2, STORED: 3, SHIPPED: 4, RECEIVED: 5, RETAIL: 6 };

  console.log("\n[3] Tedarik zinciri olayları kaydediliyor...");

  // Hasat
  await supply.connect(producer).recordEvent(
    productId, EventType.HARVESTED,
    "Ayvalık Zeytin Çiftliği", "Ayvalık, 39.5946° K 26.6958° D",
    "Zeytinler el ile hasat edildi. Nem: %62, Sıcaklık: 18°C", true
  );
  console.log("  ✅ Hasat kaydı eklendi");

  // İşleme
  await supply.connect(producer).recordEvent(
    productId, EventType.PROCESSED,
    "Ayvalık Soğuk Sıkım Tesisi", "Ayvalık Organize Sanayi",
    "Soğuk sıkım (<27°C). Asitlik: %0.3. ISO 22000 uyumlu.", true
  );
  console.log("  ✅ İşleme kaydı eklendi");

  // Kalite kontrolü
  await supply.connect(producer).recordEvent(
    productId, EventType.QUALITY_CHECK,
    "Tarım Bakanlığı Lab.", "Balıkesir",
    "Extra virjin standardını karşılıyor. Sertifika no: TB-2025-4421", true
  );
  console.log("  ✅ Kalite kontrolü geçti");

  // Depolama
  await supply.connect(logistics).recordEvent(
    productId, EventType.STORED,
    "İzmir Soğuk Hava Deposu", "İzmir Lojistik Merkezi",
    "Depo sıcaklığı: 12°C, Nem: %55. Kapasitesinin %80'i dolu.", true
  );
  console.log("  ✅ Depolama kaydı eklendi");

  // Sevkiyat
  await supply.connect(logistics).recordEvent(
    productId, EventType.SHIPPED,
    "AzizLog Lojistik", "İzmir → İstanbul Karayolu",
    "Araç plaka: 34 XY 1234. Taşıma sıcaklığı: 15°C. Tahmini varış: 6 saat.", true
  );
  console.log("  ✅ Sevkiyat başladı");

  // Teslim alma
  await supply.connect(retailer).recordEvent(
    productId, EventType.RECEIVED,
    "Güven Market Dağıtım Merkezi", "İstanbul, Ataşehir",
    "Ürün teslim alındı. Ambalaj hasarsız. Kontrol tarihi: " + new Date().toLocaleDateString("tr-TR"), true
  );
  console.log("  ✅ Teslim alındı");

  // Perakende
  await supply.connect(retailer).recordEvent(
    productId, EventType.RETAIL,
    "Güven Market Bağcılar Şubesi", "İstanbul, Bağcılar",
    "Raf ömrü: 24 ay. Son kullanma tarihi: 01/2027. Fiyat: 450₺", true
  );
  console.log("  ✅ Perakende rafına ulaştı");

  // -----------------------------------------------------------------------
  // ADIM 4: Tüketici sorgusu (QR kod tarama simülasyonu)
  // -----------------------------------------------------------------------
  console.log("\n[4] 📱 QR Kod Sorgusu (Tüketici Görünümü)...");
  const [report, history] = await query.getFullReport(productId);

  console.log("\n" + "─".repeat(60));
  console.log("📋 ÜRÜN RAPORU");
  console.log("─".repeat(60));
  console.log("Ürün Adı    :", report.name);
  console.log("Parti No    :", report.batchNumber);
  console.log("Menşei      :", report.origin);
  console.log("Üretim Tarihi:", new Date(Number(report.productionDate) * 1000).toLocaleDateString("tr-TR"));
  console.log("Miktar      :", report.quantity.toString(), "litre");
  console.log("Toplam Adım :", report.totalEvents.toString());
  console.log("Güvenli mi? :", report.allQualityPassed ? "✅ EVET" : "❌ HAYIR - Uyarı mevcut");
  console.log("Son Konum   :", report.currentLocation);
  console.log("─".repeat(60));
  console.log("📍 TEDARİK ZİNCİRİ ADIMLARI:");
  const eventNames = ["Hasat", "İşleme", "Kalite Kontrolü", "Depolama", "Sevkiyat", "Teslim Alma", "Perakende"];
  history.forEach((e, i) => {
    const date = new Date(Number(e.timestamp) * 1000).toLocaleString("tr-TR");
    console.log(`  ${i + 1}. [${eventNames[Number(e.eventType)]}] ${e.actorName} - ${e.location}`);
    console.log(`     📅 ${date} | ✅ Kalite: ${e.qualityPassed ? "Geçti" : "BAŞARISIZ"}`);
  });
  console.log("─".repeat(60));
  console.log("\n🎉 Demo tamamlandı! Tüm veriler blok zincirinde değiştirilemez şekilde saklandı.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
