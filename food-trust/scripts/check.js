const { ethers } = require("hardhat");
async function main() {
  const addr = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const registry = await ethers.getContractAt("ProductRegistry", addr);
  const total = await registry.getTotalProducts();
  console.log("Toplam ürün:", total.toString());
  for (let i = 1; i <= Number(total); i++) {
    const p = await registry.getProduct(i);
    console.log(`Ürün #${i}:`, p.name, p.batchNumber);
  }
}
main().catch(console.error);
