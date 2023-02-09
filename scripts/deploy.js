///this is the initial deployment script i made but i changed my mind the last minute and remembered to use an upgradeable proxy pattern.
///it might be handy in the future tho, so i'm keeping it here

const hre = require("hardhat")
const { items } = require("../src/items.json")

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

async function main() {
  // Setup accounts
  const [deployer] = await ethers.getSigners()

  // Deploy Openmarket
  const Openmarket = await hre.ethers.getContractFactory("Openmarket")
  const openmarket = await Openmarket.deploy()
  await openmarket.deployed()

  console.log(`Deployed Openmarket Contract at: ${openmarket.address}\n`)

  // Listing items...
  for (let i = 0; i < items.length; i++) {
    const transaction = await openmarket.connect(deployer).list(
      items[i].id,
      items[i].name,
      items[i].category,
      items[i].image,
      tokens(items[i].price),
      items[i].rating,
      items[i].stock,
    )

    await transaction.wait()

    console.log(`Listed item ${items[i].id}: ${items[i].name}`)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
