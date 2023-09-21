const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

// STEP- 4---------------------------------------------------------------------------------------------------------
// Setup the test environment, deploy the RealEstate.sol contract.

describe('Escrow', () => {
    let buyer, seller, inspector, lender
    let realEstate, escrow
// STEP- 8-----------------------------------------------------------------------------------------------------------
    // Create a beforeEach async function, for Describe Deployement.
    beforeEach(async () => {
// STEP- 6 -----------------------------------------------------------------------------------------------------------
        // Setup accounts
        [buyer, seller, inspector, lender] = await ethers.getSigners() // Destructring method of assigning Array.

// STEP- 4.1 ----------------------------------------------------------------------------------------------------------
        // Deploy Real Estate
        const RealEstate = await ethers.getContractFactory('RealEstate')
        realEstate = await RealEstate.deploy()
// STEP- 5 ----------------------------------------------------------------------------------------------------------
        // Mint 
        let transaction = await realEstate.connect(seller).mint("https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS")
        await transaction.wait()
// STEP- 7 ----------------------------------------------------------------------------------------------------------
        // Deploy Escrow
        const Escrow = await ethers.getContractFactory('Escrow')
        escrow = await Escrow.deploy(
            realEstate.address,
            seller.address,
            inspector.address,
            lender.address
        )
// STEP- 9 -----------------------------------------------------------------------------------------------------------
        // Approve Property
        // connecting to realEstate contract is just to use approve function of realestate contract, to use predefined rules defined in rE contact
        // since the tranferFrom function is also used of realEstate contract, so we have to use approve function only of realEstate contract.
        // and by below syntax , seller is giving authority to escrow contract. 
        transaction = await realEstate.connect(seller).approve(escrow.address, 1)
        await transaction.wait()
// STEP- 10 ----------------------------------------------------------------------------------------------------------
        // List Property
        transaction = await escrow.connect(seller).list(1, buyer.address, tokens(10), tokens(5))
        await transaction.wait()
    })
// STEP- 8.1 ---------------------------------------------------------------------------------------------------------
    // After "beforeEach" function.
    describe('Deployment', () => {
        it('Returns NFT address', async () => {
            const result = await escrow.nftAddress()
            expect(result).to.be.equal(realEstate.address)
        })

        it('Returns seller', async () => {
            const result = await escrow.seller()
            expect(result).to.be.equal(seller.address)
        })

        it('Returns inspector', async () => {
            const result = await escrow.inspector()
            expect(result).to.be.equal(inspector.address)
        })

        it('Returns lender', async () => {
            const result = await escrow.lender()
            expect(result).to.be.equal(lender.address)
        })
    })
// STEP- 11.1 -----------------------------------------------------------------------------------------------------------
    // Test for Listing.
    describe('Listing', () => {
        it('Updates as listed', async () => {
            const result = await escrow.isListed(1)
            expect(result).to.be.equal(true)
        })

        it('Returns buyer', async () => {
            const result = await escrow.buyer(1)
            expect(result).to.be.equal(buyer.address)
        })

        it('Returns purchase price', async () => {
            const result = await escrow.purchasePrice(1)
            expect(result).to.be.equal(tokens(10))
        })

        it('Returns escrow amount', async () => {
            const result = await escrow.escrowAmount(1)
            expect(result).to.be.equal(tokens(5))
        })

        it('Updates ownership', async () => {
            expect(await realEstate.ownerOf(1)).to.be.equal(escrow.address)
        })
    })
// STEP -13 ----------------------------------------------------------------------------------------------------------------
    // Creating "Deposits" describe
    describe('Deposits', () => {
        beforeEach(async () => {
            const transaction = await escrow.connect(buyer).depositEarnest(1, { value: tokens(5) })
            await transaction.wait()
        })

        it('Updates contract balance', async () => {
            const result = await escrow.getBalance() // Creating function in escrow contract
            expect(result).to.be.equal(tokens(5))
        })
    })
// STEP- 15 -----------------------------------------------------------------------------------------------------------------
    // Creating "Inspection" describe
    describe('Inspection', () => {
        beforeEach(async () => {
            const transaction = await escrow.connect(inspector).updateInspectionStatus(1, true)
            await transaction.wait()
        })

        it('Updates inspection status', async () => {
            const result = await escrow.inspectionPassed(1)
            expect(result).to.be.equal(true)
        })
    })
// STEP- 16 -----------------------------------------------------------------------------------------------------------------
    // Creating "Approval" describe
    describe('Approval', () => {
        beforeEach(async () => {
            let transaction = await escrow.connect(buyer).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(seller).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(lender).approveSale(1)
            await transaction.wait()
        })
// then ---------------------------------------------------------------------
        it('Updates approval status', async () => {
            expect(await escrow.approval(1, buyer.address)).to.be.equal(true)
            expect(await escrow.approval(1, seller.address)).to.be.equal(true)
            expect(await escrow.approval(1, lender.address)).to.be.equal(true)
        })
    })
// STEP- 18 -------------------------------------------------------------------------------------
    // Creating "Sale" describe
    describe('Sale', () => {
        beforeEach(async () => {

            let transaction = await escrow.connect(buyer).depositEarnest(1, { value: tokens(5) })
            await transaction.wait()

            transaction = await escrow.connect(inspector).updateInspectionStatus(1, true)
            await transaction.wait()

            transaction = await escrow.connect(buyer).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(seller).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(lender).approveSale(1)
            await transaction.wait()
// STEP- 18.1 ------------------------------------------------------------------------------------
            // The below code is where, the requirememnt of 'receive() external payable {}' is needed in Escrow.sol.
            await lender.sendTransaction({ to: escrow.address, value: tokens(5) })

            transaction = await escrow.connect(seller).finalizeSale(1)
            await transaction.wait()
        })

// STEP- 18.2 -------------------------------------------------------------------------------------
        // Below two codes as final check.
        it('Updates ownership', async () => {
            expect(await realEstate.ownerOf(1)).to.be.equal(buyer.address)
        })

        it('Updates balance', async () => {
            expect(await escrow.getBalance()).to.be.equal(0)
        })
    })
})
