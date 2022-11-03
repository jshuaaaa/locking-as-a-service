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
      startTime = 1
      endTime = 100
      depositAmount = 99
    })

    it("When creating a stream it increments nextStreamId", async function() {
      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)
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
      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)

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

    it("Gets reverted when deposit amount is zero", async function() {
      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)
      expect(vester.createStream(
        tokenAddress,
        user,
        startTime,
        endTime,
        0
      )).to.be.revertedWith("DepositAmountTooLow")
    })

    it("Gets reverted when start time is zero", async function() {
      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)
      expect(vester.createStream(
        tokenAddress,
        user,
        0,
        endTime,
        depositAmount
      )).to.be.revertedWith("StartTimePassed")
    })

    it("Gets reverted if contract is the user", async function() {
      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)
      expect(vester.createStream(
        tokenAddress,
        vester.address,
        startTime,
        endTime,
        depositAmount
      )).to.be.revertedWith("ContractCantBeUser")
    })
  })

  describe('withdrawFromStream', () => {
    let user, startTime, endTime, depositAmount, vester
    beforeEach(async function() {
      vester = await ethers.getContract("Vester", deployer)
      user = (await getNamedAccounts()).user
      startTime = 1
      endTime = 100
      depositAmount = 99

      const approve = await token.approve(vester.address, depositAmount)
      const approveReciept = await approve.wait(1)

      const createStream = await vester.createStream(
      tokenAddress,
      user,
      startTime,
      endTime,
      depositAmount
    )
    await network.provider.send("evm_increaseTime", [15000])
    await network.provider.send("evm_mine", [])
  });

  it("Only allows user to withdraw", async function() {
    expect(vester.withdrawFromStream(1,1)).to.be.revertedWith("NotYourStream")
    })
  

  it("Withdraws one token from the stream", async function() {
    const getUser = await ethers.getSigner(user)
    const connectedUser = vester.connect(getUser)
    const withdraw = await connectedUser.withdrawFromStream(1,1)
    const withdrawReciept = await withdraw.wait(1)
    const tokenBalance = await token.balanceOf(user)
    assert.equal(tokenBalance.toString(), "1")
  })

  it("After withdrawing substracts the amount of tokens vested left", async function() {
    const getUser = await ethers.getSigner(user)
    const connectedUser = vester.connect(getUser)
    const withdraw = await connectedUser.withdrawFromStream(1,1)
    const withdrawReciept = await withdraw.wait(1)

    const viewStream = await vester.viewStream("1")
    assert.equal(viewStream.balance.toString(), (depositAmount - 1).toString())
  })

  it("Checks that after user withdraws his whole balance, we delete the stream", async function() {
    await network.provider.send("evm_increaseTime", [150000])
    await network.provider.send("evm_mine", [])
    const getUser = await ethers.getSigner(user)
    const connectedUser = vester.connect(getUser)
    const redeemable = await vester.viewStream("1")
    console.log(redeemable.ratesPerSecond.toString())
    const withdraw = await connectedUser.withdrawFromStream(1,depositAmount)
    const withdrawReciept = await withdraw.wait(1)
    const balance = await token.balanceOf(user)
    expect(vester.viewStream("1")).to.be.revertedWith("StreamDoesntExist")
    assert.equal(balance.toNumber(), depositAmount)
  })

})
})