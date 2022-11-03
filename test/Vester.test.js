const { await, expect } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")

describe("Vester unit tests", function() {
  let deployer
  let vester
  
  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer
    vester = ethers.getContract("Vester", deployer)
  })

  describe("createStream", async function() {
    let tokenAddress, user, startTime, endTime, depositAmount
    beforeEach(async function() {
      let token = await ethers.getContract("Token", deployer)
      tokenAddress = token.address
      let user = (await getNamedAccounts()).user
      startTime = 0
      endTime = 10
      depositAmount = "100000"
    })
  })
})