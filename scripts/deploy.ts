import { ethers } from "hardhat";

async function main() {

  const EscrowController =
    await ethers.getContractFactory(
      "EscrowController"
    );

  const escrow =
    await EscrowController.deploy();

  await escrow.waitForDeployment();

  console.log(
    "EscrowController deployed to:",
    await escrow.getAddress()
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});