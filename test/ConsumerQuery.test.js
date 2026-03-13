const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ConsumerQuery", function () {
  let productRegistry, supplyChain, consumerQuery;
  let owner;
  let productId;

  const EventType = {
    HARVESTED: 0,
    PROCESSED: 1,
    QUALITY_CHECK: 2,
    STORED: 3,
    SHIPPED: 4,
    RECEIVED: 5,
    RETAIL: 6,
  };

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // Deploy
    const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
    productRegistry = await ProductRegistry.deploy();
    await productRegistry.waitForDeployment();

    const SupplyChain = await ethers.getContractFactory("SupplyChain");
    supplyChain = await SupplyChain.deploy(await productRegistry.getAddress());
    await supplyChain.waitForDeployment();

    const ConsumerQuery = await ethers.getContractFactory("ConsumerQuery");
    consumerQuery = await ConsumerQuery.deploy(
      await productRegistry.getAddress(),
      await supplyChain.getAddress()
    );
    await consumerQuery.waitForDeployment();

    // Test ürünü kaydet
    const productionDate = Math.floor(Date.now() / 1000);
    await productRegistry.registerProduct("Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500);
    productId = 1;
  });

  // -----------------------------------------------------------------------
  // getFullReport
  // -----------------------------------------------------------------------
  describe("getFullReport", function () {
    it("Olay yokken temel bilgileri döndürmeli", async function () {
      const [report, history] = await consumerQuery.getFullReport(productId);

      expect(report.productId).to.equal(1);
      expect(report.name).to.equal("Zeytinyağı");
      expect(report.batchNumber).to.equal("LOT-001");
      expect(report.origin).to.equal("Ayvalık");
      expect(report.totalEvents).to.equal(0);
      expect(report.allQualityPassed).to.equal(true);
      expect(history.length).to.equal(0);
    });

    it("Tüm olaylar kalite geçti ise allQualityPassed true olmalı", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.SHIPPED, "Lojistik", "İzmir", "Sevkiyat", true);

      const [report] = await consumerQuery.getFullReport(productId);
      expect(report.allQualityPassed).to.equal(true);
      expect(report.totalEvents).to.equal(2);
    });

    it("Herhangi bir olay kalite başarısız ise allQualityPassed false olmalı", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.QUALITY_CHECK, "Lab", "İzmir", "Sıcaklık hatası", false);
      await supplyChain.recordEvent(productId, EventType.RETAIL, "Market", "Ankara", "Satışa sunuldu", true);

      const [report] = await consumerQuery.getFullReport(productId);
      expect(report.allQualityPassed).to.equal(false);
    });

    it("currentLocation son olayın konumunu göstermeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "", true);
      await supplyChain.recordEvent(productId, EventType.SHIPPED, "Lojistik", "İzmir", "", true);
      await supplyChain.recordEvent(productId, EventType.RETAIL, "Market", "Ankara", "", true);

      const [report] = await consumerQuery.getFullReport(productId);
      expect(report.currentLocation).to.equal("Ankara");
    });

    it("Geçmiş tüm olayları içermeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.PROCESSED, "Fabrika", "İzmir", "İşleme", true);
      await supplyChain.recordEvent(productId, EventType.STORED, "Depo", "İzmir", "Depolama", true);
      await supplyChain.recordEvent(productId, EventType.RETAIL, "Market", "Ankara", "Satış", true);

      const [report, history] = await consumerQuery.getFullReport(productId);
      expect(history.length).to.equal(4);
      expect(report.totalEvents).to.equal(4);
    });
  });

  // -----------------------------------------------------------------------
  // getQuickSummary
  // -----------------------------------------------------------------------
  describe("getQuickSummary", function () {
    it("Doğru özet bilgilerini döndürmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.RETAIL, "Market", "Ankara", "Satış", true);

      const [name, origin, totalSteps, isSafe, currentLocation] =
        await consumerQuery.getQuickSummary(productId);

      expect(name).to.equal("Zeytinyağı");
      expect(origin).to.equal("Ayvalık");
      expect(totalSteps).to.equal(2);
      expect(isSafe).to.equal(true);
      expect(currentLocation).to.equal("Ankara");
    });

    it("Kalite hatası varsa isSafe false olmalı", async function () {
      await supplyChain.recordEvent(productId, EventType.QUALITY_CHECK, "Lab", "İzmir", "Hata", false);

      const [, , , isSafe] = await consumerQuery.getQuickSummary(productId);
      expect(isSafe).to.equal(false);
    });

    it("Olay yokken menşei currentLocation olarak dönmeli", async function () {
      const [, origin, totalSteps, , currentLocation] =
        await consumerQuery.getQuickSummary(productId);

      expect(totalSteps).to.equal(0);
      expect(currentLocation).to.equal(origin);
    });
  });

  // -----------------------------------------------------------------------
  // Tam Senaryo: Zeytinyağı Tarladan Markete
  // -----------------------------------------------------------------------
  describe("Uçtan Uca Senaryo — Zeytinyağı Tarladan Markete", function () {
    it("6 adımlı tam tedarik zinciri doğru izlenmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED,  "Ayvalık Çiftliği",     "Ayvalık, Balıkesir", "Hasat tamamlandı", true);
      await supplyChain.recordEvent(productId, EventType.PROCESSED,  "Zeytinyağı Fabrikası", "İzmir",              "Soğuk sıkım", true);
      await supplyChain.recordEvent(productId, EventType.QUALITY_CHECK, "ISO Lab",            "İzmir",              "Asitlik: %0.3", true);
      await supplyChain.recordEvent(productId, EventType.STORED,     "Merkez Depo",          "İzmir",              "8°C soğuk depo", true);
      await supplyChain.recordEvent(productId, EventType.SHIPPED,    "ABC Lojistik",         "İzmir → Ankara",     "72 saat", true);
      await supplyChain.recordEvent(productId, EventType.RETAIL,     "Migros Market",        "Ankara",             "Raflara yerleştirildi", true);

      const [report, history] = await consumerQuery.getFullReport(productId);

      expect(report.name).to.equal("Zeytinyağı");
      expect(report.totalEvents).to.equal(6);
      expect(report.allQualityPassed).to.equal(true);
      expect(report.currentLocation).to.equal("Ankara");
      expect(history[0].eventType).to.equal(EventType.HARVESTED);
      expect(history[5].eventType).to.equal(EventType.RETAIL);
    });
  });
});
