const { await, expect, assert } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")

describe("Vester unit tests", function() {
  let deployer
  let vester
  let tokenAddress, token
  
  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer
    await deployments.fixture(["all"])
    token = await ethers.getContract("Token", deployer)
    tokenAddress = token.address
    vester = ethers.getContract("Vester", deployer)
  })

  describe("Token", async function() {
    it("Token gets minted correctly", async function() {
      const tokenA = await ethers.getContract("Token")
      console.log(token.address)
      assert.equal(tokenA.address, tokenAddress)
    })

    it("Token is minted correctly", async function() {
      const balance = await token.balanceOf(deployer)
      const totalSupply = await token.totalSupply()
      assert.equal(totalSupply.toString(), balance.toString())
    })
  })

  describe("createStream", async function() {
    let user, startTime, endTime, depositAmount, vester
    beforeEach(async function() {
      vester = await ethers.getContract("Vester", deployer)
      user = (await getNamedAccounts()).user
      startTime = 0
      endTime = 10
      depositAmount = "100000"
    })

    it("When creating a stream it increments nextStreamId", async function() {
      const oldStreamId = await vester.viewNextStreamId()
      const createStream = await vester.createStream(
        tokenAddress,
        user,
        startTime,
        endTime,
        depositAmount
      )
      const newStreamId = await vester.viewNextStreamId()

      assert.equal(oldStreamId.toString(), "1")
      assert.equal(newStreamId.toString(), "2")
    })

  it("Creates a stream and saves it properly", async function() {
    const createStream = await vester.createStream(
      tokenAddress,
      user,
      startTime,
      endTime,
      depositAmount
    )
    const stream = await vester.viewStream("1")

    assert.equal(stream.user, user)
    assert.equal(stream.tokenAddress, tokenAddress)
    assert.equal(stream.startTime, startTime)
    assert.equal(stream.endTime, endTime)
    assert.equal(stream.depositAmount, depositAmount)
  })
  })
})