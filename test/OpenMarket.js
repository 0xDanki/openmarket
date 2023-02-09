const { expect } = require("chai")
const { ethers } = require("hardhat")

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

// Global constants for registering a farmer...
const FNAME = "Danki"
const CITY = "Baguio"
const BARANGAY = "Burnham"

// Global constants for listing an item...
const NAME = "Pechay"
const CATEGORY = "Vegetable"
const IMAGE = "https://ipfs.io/ipfs/QmTYEboq8raiBs7GTUg2yLXB3PMz6HuBNgNfSZBx5Msztg/shoes.jpg"
const UNIT = "basket"
const COST = tokens(1)
const RATING = 4
const STOCK = 56

// Global constants for buying an item...
const ID = 1
const BUYERADDR = "Baguio"
const PHONE = 099777898


describe("Openmarket", () => {
  let openmarket
  let deployer, buyer

  beforeEach(async () => {
    // Setup accounts
    [deployer, buyer] = await ethers.getSigners()

    // Deploy contract
    const Openmarket = await ethers.getContractFactory("Openmarket")
    openmarket = await Openmarket.deploy()
  })

  describe("Deployment", () => {
    it("Sets the owner", async () => {
      expect(await openmarket.owner()).to.equal(deployer.address)
    })
  })

  describe("Farmer Registration", () => {
    let transaction

    beforeEach(async () => {
      // Register as a farmer
      transaction = await openmarket.connect(deployer).addFarmer(FNAME, CITY, BARANGAY)
      await transaction.wait()
    })

    it("Returns farmer attributes", async () => {
      const farmer = await openmarket.farmers(deployer.address)

      expect(farmer.name).to.equal(FNAME)
      expect(farmer.city).to.equal(CITY)
      expect(farmer.barangay).to.equal(BARANGAY)
      expect(farmer.isRegistered).to.equal(true)
    })

    it("Emits FarmerRegistered event", () => {
      expect(transaction).to.emit(openmarket, "FarmerRegistered")
    })
  })

  describe("Listing", () => {
    let transaction

    beforeEach(async () => {
      // Register as a farmer
      transaction = await openmarket.connect(deployer).addFarmer(FNAME, CITY, BARANGAY)
      await transaction.wait()

      // List an item
      transaction = await openmarket.connect(deployer).list(NAME, CATEGORY, IMAGE, UNIT, COST, RATING, STOCK)
      await transaction.wait()
    })

    it("Returns item attributes", async () => {
      const item = await openmarket.items(1)

      expect(item.id).to.equal(1)
      expect(item.name).to.equal(NAME)
      expect(item.category).to.equal(CATEGORY)
      expect(item.image).to.equal(IMAGE)
      expect(item.unit).to.equal(UNIT)
      expect(item.cost).to.equal(COST)
      expect(item.rating).to.equal(RATING)
      expect(item.stock).to.equal(STOCK)
    })

    it("Emits List event", () => {
      expect(transaction).to.emit(openmarket, "List")
    })
  })

  describe("Buying", () => {
    let transaction

    beforeEach(async () => {

      // Register as a farmer
      transaction = await openmarket.connect(deployer).addFarmer(FNAME, CITY, BARANGAY)
      await transaction.wait()

      // List an item
      transaction = await openmarket.connect(deployer).list(NAME, CATEGORY, IMAGE, UNIT, COST, RATING, STOCK)
      await transaction.wait()

      // Get the initial balances
      initialSellerBalance = await ethers.provider.getBalance(deployer.address)
      initialBuyerBalance = await ethers.provider.getBalance(buyer.address)

      // Buy an item
      transaction = await openmarket.connect(buyer).buy(ID, BUYERADDR, PHONE, { value: COST })
      await transaction.wait()
    })

    it("Updates buyer's order count", async () => {
      const result = await openmarket.orderCount(buyer.address)
      expect(result).to.equal(1)
    })

    it("Adds the order", async () => {
      const order = await openmarket.orders(buyer.address, 1)

      expect(order.time).to.be.greaterThan(0)
      expect(order.item.name).to.equal(NAME)
    })

    it("Updates buyer and seller balances", async () => {
      SellerBalance = await ethers.provider.getBalance(deployer.address)
      BuyerBalance = await ethers.provider.getBalance(buyer.address)
      expect(SellerBalance).to.be.greaterThan(initialSellerBalance)
      expect(BuyerBalance).to.be.lessThan(initialBuyerBalance)
    })

    it("Emits Buy event", () => {
      expect(transaction).to.emit(openmarket, "Buy")
    })
  })

  describe("Delisting", () => {
    let transaction

    beforeEach(async () => {

      // Register as a farmer
      transaction = await openmarket.connect(deployer).addFarmer(FNAME, CITY, BARANGAY)
      await transaction.wait()

      // List an item
      transaction = await openmarket.connect(deployer).list(NAME, CATEGORY, IMAGE, UNIT, COST, RATING, STOCK)
      await transaction.wait()

      // Buy an item
      transaction = await openmarket.connect(buyer).buy(ID, BUYERADDR, PHONE, { value: COST })
      await transaction.wait()

      // Delist an item
      transaction = await openmarket.connect(deployer).deleteItem(ID)
      await transaction.wait()
      item = await openmarket.items(ID)
      expect(item.stock.toNumber()).to.equal(0)
    })
  })
})
