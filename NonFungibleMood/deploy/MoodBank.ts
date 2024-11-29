import assert from 'assert'
const hre = require('hardhat')

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'MoodBank'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre
    const network = await hre.ethers.provider.getNetwork()
    const networkId = network.chainId

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName]

export default deploy
