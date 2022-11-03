// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {network, ethers} = require("hardhat")

module.exports = async function(hre) {
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = network.config.chainId

    console.log("deploying")
    const vester = await deploy("Vester", {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1
    })

    const token = await deploy("Token", {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1
    })

    console.log(`Deployed succesfully to${vester.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

