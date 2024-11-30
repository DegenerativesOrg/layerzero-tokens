// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        'sepolia-testnet': {
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: 'https://rpc.sepolia.org/',
            accounts,
        },
        'base-testnet': {
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: 'https://sepolia.base.org/',
            accounts,
        },
        'core-testnet': {
            eid: EndpointId.COREDAO_V2_TESTNET,
            url: 'https://rpc.test.btcs.network/',
            accounts,
        },
        'etherlink-testnet': {
            eid: EndpointId.ETHERLINK_V2_TESTNET,
            url: 'https://node.ghostnet.etherlink.com/',
            accounts,
        },
        'amoy-testnet': {
            eid: EndpointId.AMOY_V2_TESTNET,
            url: 'https://rpc-amoy.polygon.technology/',
            accounts,
        },
        'unichain-testnet': {
            eid: EndpointId.UNICHAIN_V2_TESTNET,
            url: 'https://sepolia.unichain.org/',
            accounts,
        },
        'taiko-testnet': {
            eid: EndpointId.TAIKO_V2_TESTNET,
            url: 'https://holesky.drpc.org/',
            accounts,
        },
        hardhat: {
            // Need this for testing because TestHelperOz5.sol is exceeding the compiled contract size limit
            allowUnlimitedContractSize: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
}

export default config
