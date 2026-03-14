const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer, producer, processor, logistics, warehouse, inspector, retailer, customer] =
    await hre.ethers.getSigners();

  console.log("Deploying contracts with:", deployer.address);

  // 1. RoleManager
  const RoleManager = await hre.ethers.getContractFactory("RoleManager");
  const roleManager = await RoleManager.deploy();
  await roleManager.waitForDeployment();
  console.log("RoleManager:", await roleManager.getAddress());

  // 2. BatchRegistry
  const BatchRegistry = await hre.ethers.getContractFactory("BatchRegistry");
  const batchRegistry = await BatchRegistry.deploy(await roleManager.getAddress());
  await batchRegistry.waitForDeployment();
  console.log("BatchRegistry:", await batchRegistry.getAddress());

  // 3. ShipmentRegistry
  const ShipmentRegistry = await hre.ethers.getContractFactory("ShipmentRegistry");
  const shipmentRegistry = await ShipmentRegistry.deploy(await roleManager.getAddress());
  await shipmentRegistry.waitForDeployment();
  console.log("ShipmentRegistry:", await shipmentRegistry.getAddress());

  // 4. QualityRegistry
  const QualityRegistry = await hre.ethers.getContractFactory("QualityRegistry");
  const qualityRegistry = await QualityRegistry.deploy(await roleManager.getAddress());
  await qualityRegistry.waitForDeployment();
  console.log("QualityRegistry:", await qualityRegistry.getAddress());

  // Assign test roles
  const Role = { NONE:0, CUSTOMER:1, RETAILER:2, LOGISTICS:3, WAREHOUSE:4, INSPECTOR:5, PROCESSOR:6, PRODUCER:7, ADMIN:8 };
  await roleManager.grantRole(producer.address,  Role.PRODUCER);
  await roleManager.grantRole(processor.address, Role.PROCESSOR);
  await roleManager.grantRole(logistics.address, Role.LOGISTICS);
  await roleManager.grantRole(warehouse.address, Role.WAREHOUSE);
  await roleManager.grantRole(inspector.address, Role.INSPECTOR);
  await roleManager.grantRole(retailer.address,  Role.RETAILER);
  await roleManager.grantRole(customer.address,  Role.CUSTOMER);
  console.log("Test roles assigned.");

  const addresses = {
    RoleManager:      await roleManager.getAddress(),
    BatchRegistry:    await batchRegistry.getAddress(),
    ShipmentRegistry: await shipmentRegistry.getAddress(),
    QualityRegistry:  await qualityRegistry.getAddress(),
    testAccounts: {
      admin:     deployer.address,
      producer:  producer.address,
      processor: processor.address,
      logistics: logistics.address,
      warehouse: warehouse.address,
      inspector: inspector.address,
      retailer:  retailer.address,
      customer:  customer.address,
    }
  };

  fs.writeFileSync(
    path.join(__dirname, "../deployed-addresses.json"),
    JSON.stringify(addresses, null, 2)
  );
  console.log("Addresses saved to deployed-addresses.json");
}

main().catch((e) => { console.error(e); process.exit(1); });
