import * as dotenv from 'dotenv'

import { HardhatUserConfig, subtask } from 'hardhat/config'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'

// hack :D
const {
	getEtherscanEndpoints
} = require('@nomiclabs/hardhat-etherscan/dist/src/network/prober')

dotenv.config()

const accounts = process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []

const config: HardhatUserConfig = {
	solidity: '0.8.14',
	networks: {
		rei: {
			url: 'https://rei-rpc.moonrhythm.io',
			chainId: 55555,
			accounts
		}
	},
	etherscan: {
		apiKey: 'yay :D',
		customChains: [
			{
				network: 'rei',
				chainId: 55555,
				urls: {
					apiURL: 'https://reiscan.com/api',
					browserURL: 'https://reiscan.com/'
				}
			}
		]
	}
}

export default config
