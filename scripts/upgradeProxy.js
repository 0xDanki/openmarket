const { ethers, upgrades } = require('hardhat');

// TO DO: Place the address of your proxy here!
const proxyAddress = '';

async function main() {
  const VendingMachineV2 = await ethers.getContractFactory('OpenMarketV2');
  const upgraded = await upgrades.upgradeProxy(proxyAddress, OpenMarketV2);

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
  );

  console.log("The current contract owner is: " + upgraded.owner());
  console.log('Implementation contract address: ' + implementationAddress);
}

main();