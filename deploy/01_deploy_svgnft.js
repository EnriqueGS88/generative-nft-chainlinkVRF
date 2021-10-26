const fs = require('fs');
// This ethers is not needed
//const { ethers } = require('hardhat');
let {networkConfig} = require('../helper-hardhat-config')



module.exports = async({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = await getChainId()

    log("-_-_-_-_-_-GET_-_READY_-_-_-_-_-STUFF_-_-_-IS_-_ABOUT_-_-_-TO_-_HAPPEN!!_-_-")

    const SVGNFT = await deploy("SVGNFT", {
        from: deployer,
        log: true
    })
    log(`You have deployed an NFT contract to ${SVGNFT.address}`)

    //Next, read the content of the SVG file stored in the folder defined in "filepath"
    let filepath = "./img/triangle.svg"
    let svg = fs.readFileSync(filepath, {encoding: "utf8"})

    // This fetches all Contract information from SVGNFT
    const svgNFTContract = await ethers.getContractFactory("SVGNFT")
    // This provides the signature of who deployed this contract - the account 0 of that mnemonic
    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]
    // This is the line that gets the SVG NFT
    const svgNFT = new ethers.Contract(SVGNFT.address, svgNFTContract.interface, signer)
    const networkName = networkConfig[chainId]['name']
    log(`Verify with: \n npx hardhat verify --network ${networkName} ${svgNFT.address}`)

    let transactionResponse = await svgNFT.create(svg)
    // we will wait for 1 block for this tx to get mined
    let receipt = await transactionResponse.wait(1)
    log(`You've made an NFT!`)
    log(`You can view the tokenURI here ${await svgNFT.tokenURI(0)}`)
}

module.exports.tags = ['all','svg']