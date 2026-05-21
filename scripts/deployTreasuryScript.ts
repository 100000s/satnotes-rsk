import { ethers } from "hardhat";

async function main() {
  const escrowAddress = "0xeEA468e0Aa316BfEf7B6e48a818bd3D561e5cbf8";

  const TreasuryVault = await ethers.getContractFactory("TreasuryVault");
  const treasury = await TreasuryVault.deploy(escrowAddress);

  await treasury.waitForDeployment();

  console.log("TreasuryVault deployed to:", await treasury.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
