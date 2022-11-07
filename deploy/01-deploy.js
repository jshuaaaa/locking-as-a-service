// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {network, ethers} = require("hardhat")
const { networkConfig } = require("../helper-hardhat")
const { verify } = require("../utils/verify")

module.exports = async (hre) => {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = network.config.chainId
    
    let LZEndpoint
    console.log("deploying")
    if(chainId == 31337) {
    const LZEndpointDep = await deploy("LZEndpointMock", {
      from: deployer,
      args: [1],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1
    })
    LZEndpoint = LZEndpointDep.address

    const token = await deploy("Token", {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1
    })
  } else {
    LZEndpoint = networkConfig[chainId]["LZEndpoint"]
  }

  const vester = await deploy("Vester", {
    from: deployer,
    args: [LZEndpoint],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1
  })


  if(chainId != 31337 && process.env.ETHERSCAN) {
    await verify(vester.address, [LZEndpoint])
  }

  console.log(`Deployed succesfully to${vester.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

module.exports.tags = ["all"]