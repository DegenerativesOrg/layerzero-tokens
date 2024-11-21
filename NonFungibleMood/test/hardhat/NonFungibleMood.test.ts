import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers } from 'hardhat'

import { Options } from '@layerzerolabs/lz-v2-utilities'

describe('NonFungibleMood Test', function () {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2
    // Declaration of variables to be used in the test suite
    let NonFungibleMood: ContractFactory
    let EndpointV2Mock: ContractFactory
    let ownerA: SignerWithAddress
    let ownerB: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let NonFungibleMoodA: Contract
    let NonFungibleMoodB: Contract
    let mockEndpointV2A: Contract
    let mockEndpointV2B: Contract

    // Before hook for setup that runs once before all tests in the block
    before(async function () {
        // Contract factory for our tested contract
        //
        // We are using a derived contract that exposes a mint() function for testing purposes
        NonFungibleMood = await ethers.getContractFactory('NonFungibleMoodMock')

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

        // Deploying two instances of FungibleMood contract with different identifiers and linking them to the mock LZEndpoint
        NonFungibleMoodA = await NonFungibleMood.deploy('aONFT721', 'aONFT721', mockEndpointV2A.address, ownerA.address)
        NonFungibleMoodB = await NonFungibleMood.deploy('bONFT721', 'bONFT721', mockEndpointV2B.address, ownerB.address)

        // Setting destination endpoints in the LZEndpoint mock for each NonFungibleMood instance
        await mockEndpointV2A.setDestLzEndpoint(NonFungibleMoodB.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(NonFungibleMoodA.address, mockEndpointV2A.address)

        // Setting each NonFungibleMood instance as a peer of the other in the mock LZEndpoint
        await NonFungibleMoodA.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(NonFungibleMoodB.address, 32))
        await NonFungibleMoodB.connect(ownerB).setPeer(eidA, ethers.utils.zeroPad(NonFungibleMoodA.address, 32))
    })

    // A test case to verify token transfer functionality
    it('should send a token from A address to B address', async function () {
        // Minting an initial amount of tokens to ownerA's address in the NonFungibleMoodA contract
        const initialTokenId = 0
        await NonFungibleMoodA.mint(ownerA.address, initialTokenId)

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
})
