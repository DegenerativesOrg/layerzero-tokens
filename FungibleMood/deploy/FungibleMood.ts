import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'FungibleMood'
const nonFungibleMood = '0xd8DCFCC481ecE562C5263C8C7308324DfC9043b0'
const oldMood = '0x5ae9108bC677e5269b6E71AE51DD15d19863Da1c'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    const endpointV2Deployment = await hre.deployments.get('EndpointV2')

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [endpointV2Deployment.address, deployer, nonFungibleMood],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName]

export default deploy
