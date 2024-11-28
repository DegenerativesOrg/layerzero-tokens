import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers } from 'hardhat'

import { Options } from '@layerzerolabs/lz-v2-utilities'

describe('NonFungibleMood Test', function () {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2

    let moodData: any
    let moodData1: any

    // Declaration of variables to be used in the test suite
    let NonFungibleMood: ContractFactory
    let FungibleMood: ContractFactory
    let EndpointV2Mock: ContractFactory
    let MoodBank: ContractFactory
    let ownerA: SignerWithAddress
    let ownerB: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let NonFungibleMoodA: Contract
    let NonFungibleMoodB: Contract
    let FungibleMoodA: Contract
    let FungibleMoodB: Contract
    let MoodBankA: Contract
    let MoodBankB: Contract
    let mockEndpointV2A: Contract
    let mockEndpointV2B: Contract

    // Before hook for setup that runs once before all tests in the block
    before(async function () {
        // Contract factory for our tested contract
        //
        // We are using a derived contract that exposes a mint() function for testing purposes
        NonFungibleMood = await ethers.getContractFactory('NonFungibleMood')
        FungibleMood = await ethers.getContractFactory('FungibleMood')
        MoodBank = await ethers.getContractFactory('MoodBank')

        // Fetching the first three signers (accounts) from Hardhat's local Ethereum network
        const signers = await ethers.getSigners()

        ownerA = signers.at(0)!
        ownerB = signers.at(1)!
        endpointOwner = signers.at(2)!

        // The EndpointV2Mock contract comes from @layerzerolabs/test-devtools-evm-hardhat package
        // and its artifacts are connected as external artifacts to this project
        //
        // Unfortunately, hardhat itself does not yet provide a way of connecting external artifacts,
        // so we rely on hardhat-deploy to create a ContractFactory for EndpointV2Mock
        //
        // See https://github.com/NomicFoundation/hardhat/issues/1040
        const EndpointV2MockArtifact = await deployments.getArtifact('EndpointV2Mock')
        EndpointV2Mock = new ContractFactory(EndpointV2MockArtifact.abi, EndpointV2MockArtifact.bytecode, endpointOwner)
    })

    // beforeEach hook for setup that runs before each test in the block
    beforeEach(async function () {
        // Deploying a mock LZEndpoint with the given Endpoint ID
        mockEndpointV2A = await EndpointV2Mock.deploy(eidA)
        mockEndpointV2B = await EndpointV2Mock.deploy(eidB)

        moodData = {
            chainId: 1,
            timestamp: Math.floor(Date.now() / 1000),
            emojis: ['😊', '😎', '🚀'],
            themeAddress: ownerA.address,
            bgColor: 'blue',
            fontColor: 'white',
            expansionLevel: 5,
            user: ownerA.address,
        }

        moodData1 = {
            chainId: 1,
            timestamp: Math.floor(Date.now() / 1000),
            emojis: ['🚀', '🚀', '🚀'],
            themeAddress: ownerA.address,
            bgColor: 'blue',
            fontColor: 'white',
            expansionLevel: 5,
            user: ownerA.address,
        }

        const network = await ethers.provider.getNetwork()

        // Deploying two instances of FungibleMood contract with different identifiers and linking them to the mock LZEndpoint
        NonFungibleMoodA = await NonFungibleMood.deploy(mockEndpointV2A.address, ownerA.address, network.chainId)
        NonFungibleMoodB = await NonFungibleMood.deploy(mockEndpointV2B.address, ownerB.address, network.chainId)

        FungibleMoodA = await FungibleMood.deploy(
            mockEndpointV2A.address,
            ownerA.address,
            NonFungibleMoodA.address,
            ownerB.address
        )
        FungibleMoodB = await FungibleMood.deploy(
            mockEndpointV2A.address,
            ownerA.address,
            NonFungibleMoodB.address,
            ownerB.address
        )

        // Mood Banks
        MoodBankA = await MoodBank.connect(ownerA).deploy()
        MoodBankB = await MoodBank.connect(ownerB).deploy()

        await MoodBankA.connect(ownerA).authorize(ownerA.address, true)
        await MoodBankB.connect(ownerB).authorize(ownerA.address, true)
        await MoodBankA.connect(ownerA).authorize(NonFungibleMoodA.address, true)
        await MoodBankB.connect(ownerB).authorize(NonFungibleMoodB.address, true)
        await NonFungibleMoodA.connect(ownerA).setupMoodBank(MoodBankA.address)
        await NonFungibleMoodB.connect(ownerB).setupMoodBank(MoodBankB.address)
        await NonFungibleMoodA.connect(ownerA).setupFungibleMood(FungibleMoodA.address)
        await NonFungibleMoodB.connect(ownerB).setupFungibleMood(FungibleMoodB.address)

        // Setting destination endpoints in the LZEndpoint mock for each NonFungibleMood instance
        await mockEndpointV2A.setDestLzEndpoint(NonFungibleMoodB.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(NonFungibleMoodA.address, mockEndpointV2A.address)

        // Setting each NonFungibleMood instance as a peer of the other in the mock LZEndpoint
        await NonFungibleMoodA.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(NonFungibleMoodB.address, 32))
        await NonFungibleMoodB.connect(ownerB).setPeer(eidA, ethers.utils.zeroPad(NonFungibleMoodA.address, 32))
    })

    it('should add a mood and retrieve it', async function () {
        // 1. Encode mood data

        const encodedMoodData = await MoodBankA.connect(ownerA).encodeMood(moodData)
        const moodId = await MoodBankA.connect(ownerA).addMood(encodedMoodData)

        // 2. Add mood to MoodBankA
        const moodSupply = await MoodBankA.connect(ownerA).totalMood()

        // 3. Retrieve mood data
        const retrievedMood = await MoodBankA.connect(ownerA).getMoodDataByIndex(ownerA.address, 0)

        // 4. Assertions
        expect(Number(retrievedMood.chainId)).to.equal(moodData.chainId)
        expect(Number(retrievedMood.timestamp)).to.equal(moodData.timestamp)
        expect(retrievedMood.emojis).to.deep.equal(moodData.emojis)
    })

    // A test case to verify token transfer functionality
    it('should send a token from A address to B address', async function () {
        // Minting an initial amount of tokens to ownerA's address in the NonFungibleMoodA contract

        const initialTokenId = await NonFungibleMoodA.generateTokenId(0)
        const encodedMoodData = await MoodBankA.connect(ownerA).encodeMood(moodData)
        await NonFungibleMoodA.mint(true, encodedMoodData)
        const totalSupply = await NonFungibleMoodA.totalSupply()

        // Defining extra message execution options for the send operation
        const options = Options.newOptions().addExecutorLzReceiveOption(200000, 0).toHex().toString()

        const sendParam = [eidB, ethers.utils.zeroPad(ownerB.address, 32), initialTokenId, options, '0x', '0x']

        // Fetching the native fee for the token send operation
        const [nativeFee] = await NonFungibleMoodA.quoteSend(sendParam, false)

        // Executing the send operation from NonFungibleMoodA contract
        await NonFungibleMoodA.send(sendParam, [nativeFee, 0], ownerA.address, { value: nativeFee })

        // Fetching the final token balances of ownerA and ownerB
        const finalBalanceA = await NonFungibleMoodA.balanceOf(ownerA.address)
        const finalBalanceB = await NonFungibleMoodB.balanceOf(ownerB.address)

        // Asserting that the final balances are as expected after the send operation
        expect(finalBalanceA).eql(ethers.BigNumber.from(0))
        expect(finalBalanceB).eql(ethers.BigNumber.from(1))
    })

    it('should mint and release reward token', async function () {
        // Minting an initial amount of tokens to ownerA's address in the NonFungibleMoodA contract

        const initialTokenId = await NonFungibleMoodA.generateTokenId(0)
        const encodedMoodData = await MoodBankA.connect(ownerA).encodeMood(moodData)
        await NonFungibleMoodA.mint(true, encodedMoodData)
        const totalSupply = await NonFungibleMoodA.totalSupply()

        // Fetching the final token balances of ownerA and ownerB
        const finalBalanceA = await NonFungibleMoodA.balanceOf(ownerA.address)
        const rewardBalanceA = await FungibleMoodA.balanceOf(ownerA.address)
        console.log(rewardBalanceA)

        // Asserting that the final balances are as expected after the send operation
        expect(finalBalanceA).eql(ethers.BigNumber.from(1))
        expect(Number(rewardBalanceA)).eql(1000000000000000000)
    })

    it('should accept FM and burn after mint', async function () {
        // Minting an initial amount of tokens to ownerA's address in the NonFungibleMoodA contract

        const initialTokenId = await NonFungibleMoodA.generateTokenId(0)
        const encodedMoodData = await MoodBankA.connect(ownerA).encodeMood(moodData)
        await NonFungibleMoodA.mint(true, encodedMoodData)

        const encodedMoodData1 = await MoodBankA.connect(ownerA).encodeMood(moodData1)
        await FungibleMoodA.approve(NonFungibleMoodA.address, 1000000000000000000n)
        await NonFungibleMoodA.mint(false, encodedMoodData1)

        // Fetching the final token balances of ownerA and ownerB
        const finalBalanceA = await NonFungibleMoodA.balanceOf(ownerA.address)
        const rewardBalanceA = await FungibleMoodA.balanceOf(ownerA.address)
        console.log(finalBalanceA)
        console.log(rewardBalanceA)

        // Asserting that the final balances are as expected after the send operation
        expect(Number(finalBalanceA)).eql(2)
        expect(Number(rewardBalanceA)).eql(0)
    })
})
