const hre = require("hardhat");

async function main() {
  // Deploy TestToken first
  const TestToken = await hre.ethers.getContractFactory("TestToken");
  const testToken = await TestToken.deploy();
  await testToken.waitForDeployment();

  console.log("TestToken deployed to:", await testToken.getAddress());

  // Deploy TokenVesting
  const TokenVesting = await hre.ethers.getContractFactory("TokenVesting");
  const tokenVesting = await TokenVesting.deploy(await testToken.getAddress());
  await tokenVesting.waitForDeployment();

  console.log("TokenVesting deployed to:", await tokenVesting.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});