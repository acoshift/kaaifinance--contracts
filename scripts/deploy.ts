import { ethers } from 'hardhat'
import { KaaiMaiKub__factory } from '../typechain-types'

const receiver = '0x000000950A4168ad3631e7Cd4964106fa9824834'
const signer = '0x000000507563be38B521e0A03Ff5C6993Eed6393'

async function main () {
	const signers = await ethers.getSigners()
	const C = new KaaiMaiKub__factory(signers[0])
	const c = await C.deploy(
		receiver,
		signer
	)
	await c.deployed()

	console.log('KaaiMaiKub deployed to:', c.address)
}

main().catch((error) => {
	console.error(error)
	process.exitCode = 1
})
