const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // 1. ProductRegistry
  console.log("\n📦 Deploying ProductRegistry...");
  const ProductRegistry = await ethers.getContractFactory("ProductRegistry");
  const productRegistry = await ProductRegistry.deploy();
  await productRegistry.waitForDeployment();
  const registryAddr = await productRegistry.getAddress();
  console.log("✅ ProductRegistry deployed to:", registryAddr);

  // 2. SupplyChain (ProductRegistry adresini alır)
  console.log("\n🔗 Deploying SupplyChain...");
  const SupplyChain = await ethers.getContractFactory("SupplyChain");
  const supplyChain = await SupplyChain.deploy(registryAddr);
  await supplyChain.waitForDeployment();
  const supplyAddr = await supplyChain.getAddress();
  console.log("✅ SupplyChain deployed to:", supplyAddr);

  // 3. ConsumerQuery (her iki adresi alır)
  console.log("\n🔍 Deploying ConsumerQuery...");
  const ConsumerQuery = await ethers.getContractFactory("ConsumerQuery");
  const consumerQuery = await ConsumerQuery.deploy(registryAddr, supplyAddr);
  await consumerQuery.waitForDeployment();
  const queryAddr = await consumerQuery.getAddress();
  console.log("✅ ConsumerQuery deployed to:", queryAddr);

  // Adresleri kaydet
  const addresses = {
    ProductRegistry: registryAddr,
    SupplyChain: supplyAddr,
    ConsumerQuery: queryAddr,
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    deployedAt: new Date().toISOString(),
  };

  const fs = require("fs");
  fs.writeFileSync(
    "./deployed-addresses.json",
    JSON.stringify(addresses, null, 2)
  );
  console.log("\n📄 Addresses saved to deployed-addresses.json");
  console.log(addresses);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
