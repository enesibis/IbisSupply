const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProductRegistry", function () {
  let productRegistry;
  let owner, producer1, producer2, unauthorized;

  beforeEach(async function () {
    [owner, producer1, producer2, unauthorized] = await ethers.getSigners();

    const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
    productRegistry = await ProductRegistry.deploy();
    await productRegistry.waitForDeployment();
  });

  // -----------------------------------------------------------------------
  // Yetki Yönetimi
  // -----------------------------------------------------------------------
  describe("Yetki Yönetimi", function () {
    it("Deploy sonrası owner yetkili üretici olmalı", async function () {
      expect(await productRegistry.authorizedProducers(owner.address)).to.equal(true);
    });

    it("Owner, yeni üretici yetkilendirebilmeli", async function () {
      await productRegistry.authorizeProducer(producer1.address);
      expect(await productRegistry.authorizedProducers(producer1.address)).to.equal(true);
    });

    it("Owner, üretici yetkisini iptal edebilmeli", async function () {
      await productRegistry.authorizeProducer(producer1.address);
      await productRegistry.revokeProducer(producer1.address);
      expect(await productRegistry.authorizedProducers(producer1.address)).to.equal(false);
    });

    it("Yetkisiz kullanıcı üretici yetkilendirememeli", async function () {
      await expect(
        productRegistry.connect(unauthorized).authorizeProducer(producer1.address)
      ).to.be.revertedWith("Only owner");
    });

    it("ProducerAuthorized eventi yayınlanmalı", async function () {
      await expect(productRegistry.authorizeProducer(producer1.address))
        .to.emit(productRegistry, "ProducerAuthorized")
        .withArgs(producer1.address);
    });

    it("ProducerRevoked eventi yayınlanmalı", async function () {
      await productRegistry.authorizeProducer(producer1.address);
      await expect(productRegistry.revokeProducer(producer1.address))
        .to.emit(productRegistry, "ProducerRevoked")
        .withArgs(producer1.address);
    });
  });

  // -----------------------------------------------------------------------
  // Ürün Kaydı
  // -----------------------------------------------------------------------
  describe("Ürün Kaydı", function () {
    const productionDate = Math.floor(Date.now() / 1000);

    it("Yetkili üretici ürün kaydedebilmeli", async function () {
      await productRegistry.authorizeProducer(producer1.address);
      await productRegistry
        .connect(producer1)
        .registerProduct("Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500);

      const product = await productRegistry.getProduct(1);
      expect(product.name).to.equal("Zeytinyağı");
      expect(product.batchNumber).to.equal("LOT-001");
      expect(product.origin).to.equal("Ayvalık");
      expect(product.producer).to.equal(producer1.address);
      expect(product.quantity).to.equal(500);
      expect(product.isActive).to.equal(true);
    });

    it("Yetkisiz kullanıcı ürün kaydedemenmeli", async function () {
      await expect(
        productRegistry
          .connect(unauthorized)
          .registerProduct("Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500)
      ).to.be.revertedWith("Not authorized producer");
    });

    it("Ürün ID'si 1'den başlamalı ve artmalı", async function () {
      const tx1 = await productRegistry.registerProduct(
        "Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500
      );
      await tx1.wait();
      const tx2 = await productRegistry.registerProduct(
        "Sızma Yağ", "LOT-002", "Edremit", productionDate, 200
      );
      await tx2.wait();

      expect(await productRegistry.getTotalProducts()).to.equal(2);
    });

    it("Kayıt olmayan ürün sorgulanınca hata vermeli", async function () {
      await expect(productRegistry.getProduct(999)).to.be.revertedWith("Product not found");
    });

    it("ProductRegistered eventi doğru argümanlarla yayınlanmalı", async function () {
      await expect(
        productRegistry.registerProduct("Zeytinyağı", "LOT-001", "Ayvalık", productionDate, 500)
      )
        .to.emit(productRegistry, "ProductRegistered")
        .withArgs(1, "Zeytinyağı", "LOT-001", owner.address, productionDate);
    });

    it("Birden fazla üretici ürün kaydedebilmeli", async function () {
      await productRegistry.authorizeProducer(producer1.address);
      await productRegistry.authorizeProducer(producer2.address);

      await productRegistry.connect(producer1).registerProduct("Zeytinyağı", "LOT-A", "Ayvalık", productionDate, 500);
      await productRegistry.connect(producer2).registerProduct("Sızma Yağ", "LOT-B", "Edremit", productionDate, 300);

      const p1 = await productRegistry.getProduct(1);
      const p2 = await productRegistry.getProduct(2);

      expect(p1.producer).to.equal(producer1.address);
      expect(p2.producer).to.equal(producer2.address);
    });
  });
});
