import assert from 'assert'
const hre = require('hardhat')

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'NonFungibleMood'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre
    const network = await hre.ethers.provider.getNetwork()
    const networkId = network.chainId

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    // console.log(`Network: ${hre.network.name}`)
    // console.log(`ChainID: ${networkId}`)
    // console.log(`Deployer: ${deployer}`)

    const endpointV2Deployment = await hre.deployments.get('EndpointV2')

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [
            endpointV2Deployment.address, // LayerZero's EndpointV2 address
            deployer, // owner
            networkId, // chainId
        ],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName]

export default deploy
