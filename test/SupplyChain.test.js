const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SupplyChain", function () {
  let productRegistry, supplyChain;
  let owner, actor1, actor2, unauthorized;
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
    [owner, actor1, actor2, unauthorized] = await ethers.getSigners();

    // ProductRegistry deploy
    const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
    productRegistry = await ProductRegistry.deploy();
    await productRegistry.waitForDeployment();

    // SupplyChain deploy
    const SupplyChain = await ethers.getContractFactory("SupplyChain");
    supplyChain = await SupplyChain.deploy(await productRegistry.getAddress());
    await supplyChain.waitForDeployment();

    // Test için bir ürün kaydet
    const productionDate = Math.floor(Date.now() / 1000);
    const tx = await productRegistry.registerProduct(
      "Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500
    );
    await tx.wait();
    productId = 1;
  });

  // -----------------------------------------------------------------------
  // Yetki Yönetimi
  // -----------------------------------------------------------------------
  describe("Yetki Yönetimi", function () {
    it("Deploy sonrası owner yetkili aktör olmalı", async function () {
      expect(await supplyChain.authorizedActors(owner.address)).to.equal(true);
    });

    it("Owner yeni aktör yetkilendirebilmeli", async function () {
      await supplyChain.authorizeActor(actor1.address);
      expect(await supplyChain.authorizedActors(actor1.address)).to.equal(true);
    });

    it("Owner aktör yetkisini iptal edebilmeli", async function () {
      await supplyChain.authorizeActor(actor1.address);
      await supplyChain.revokeActor(actor1.address);
      expect(await supplyChain.authorizedActors(actor1.address)).to.equal(false);
    });

    it("Yetkisiz kullanıcı aktör yetkilendirememeli", async function () {
      await expect(
        supplyChain.connect(unauthorized).authorizeActor(actor1.address)
      ).to.be.revertedWith("Only owner");
    });
  });

  // -----------------------------------------------------------------------
  // Olay Kaydı
  // -----------------------------------------------------------------------
  describe("Tedarik Zinciri Olay Kaydı", function () {
    it("Yetkili aktör olay kaydedebilmeli", async function () {
      await supplyChain.recordEvent(
        productId,
        EventType.HARVESTED,
        "Ayvalık Çiftliği",
        "Ayvalık, Balıkesir",
        "Hasat tamamlandı",
        true
      );

      const history = await supplyChain.getProductHistory(productId);
      expect(history.length).to.equal(1);
      expect(history[0].actorName).to.equal("Ayvalık Çiftliği");
      expect(history[0].location).to.equal("Ayvalık, Balıkesir");
      expect(history[0].qualityPassed).to.equal(true);
      expect(history[0].eventType).to.equal(EventType.HARVESTED);
    });

    it("Yetkisiz kullanıcı olay kaydedemenmeli", async function () {
      await expect(
        supplyChain.connect(unauthorized).recordEvent(
          productId, EventType.HARVESTED, "Test", "Test", "Test", true
        )
      ).to.be.revertedWith("Not authorized actor");
    });

    it("Kayıtlı olmayan ürün için olay eklenememeli", async function () {
      await expect(
        supplyChain.recordEvent(
          999, EventType.HARVESTED, "Test", "Test", "Test", true
        )
      ).to.be.revertedWith("Product not found");
    });

    it("SupplyEventRecorded eventi yayınlanmalı", async function () {
      await expect(
        supplyChain.recordEvent(
          productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true
        )
      ).to.emit(supplyChain, "SupplyEventRecorded");
    });

    it("Kalite başarısız olunca QualityAlert eventi yayınlanmalı", async function () {
      await expect(
        supplyChain.recordEvent(
          productId,
          EventType.QUALITY_CHECK,
          "Kalite Kontrol Lab",
          "İzmir",
          "Sıcaklık limiti aşıldı: 12°C",
          false
        )
      ).to.emit(supplyChain, "QualityAlert").withArgs(productId, 1, "Sıcaklık limiti aşıldı: 12°C");
    });

    it("Birden fazla olay doğru sırayla kaydedilmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.PROCESSED, "Fabrika", "İzmir", "İşleme", true);
      await supplyChain.recordEvent(productId, EventType.SHIPPED, "Lojistik", "İzmir", "Sevkiyat", true);

      const history = await supplyChain.getProductHistory(productId);
      expect(history.length).to.equal(3);
      expect(history[0].eventType).to.equal(EventType.HARVESTED);
      expect(history[1].eventType).to.equal(EventType.PROCESSED);
      expect(history[2].eventType).to.equal(EventType.SHIPPED);
    });

    it("Farklı ürünlerin geçmişleri birbirine karışmamalı", async function () {
      // İkinci ürün kaydet
      const productionDate = Math.floor(Date.now() / 1000);
      await productRegistry.registerProduct("Sızma Yağ", "LOT-002", "Edremit", productionDate, 200);

      await supplyChain.recordEvent(1, EventType.HARVESTED, "Çiftlik A", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(2, EventType.HARVESTED, "Çiftlik B", "Edremit", "Hasat", true);

      const history1 = await supplyChain.getProductHistory(1);
      const history2 = await supplyChain.getProductHistory(2);

      expect(history1.length).to.equal(1);
      expect(history2.length).to.equal(1);
      expect(history1[0].actorName).to.equal("Çiftlik A");
      expect(history2[0].actorName).to.equal("Çiftlik B");
    });
  });

  // -----------------------------------------------------------------------
  // Geri Çağırma (Recall) Simülasyonu
  // -----------------------------------------------------------------------
  describe("Geri Çağırma Simülasyonu", function () {
    it("getAffectedBatch ürün bilgisini ve geçmişini döndürmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "Çiftlik", "Ayvalık", "Hasat", true);
      await supplyChain.recordEvent(productId, EventType.STORED, "Depo", "İzmir", "Depolama", true);
      await supplyChain.recordEvent(productId, EventType.QUALITY_CHECK, "Lab", "İzmir", "Sıcaklık hatası", false);

      const [product, history] = await supplyChain.getAffectedBatch(productId);

      expect(product.name).to.equal("Zeytinyağı");
      expect(product.batchNumber).to.equal("LOT-001");
      expect(history.length).to.equal(3);
      expect(history[2].qualityPassed).to.equal(false);
    });
  });

  // -----------------------------------------------------------------------
  // Sayaçlar
  // -----------------------------------------------------------------------
  describe("Sayaçlar", function () {
    it("getTotalEvents toplam olay sayısını döndürmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "A", "B", "C", true);
      await supplyChain.recordEvent(productId, EventType.PROCESSED, "A", "B", "C", true);
      expect(await supplyChain.getTotalEvents()).to.equal(2);
    });

    it("getProductEventCount ürüne ait olay sayısını döndürmeli", async function () {
      await supplyChain.recordEvent(productId, EventType.HARVESTED, "A", "B", "C", true);
      await supplyChain.recordEvent(productId, EventType.STORED, "A", "B", "C", true);
      expect(await supplyChain.getProductEventCount(productId)).to.equal(2);
    });
  });
});
