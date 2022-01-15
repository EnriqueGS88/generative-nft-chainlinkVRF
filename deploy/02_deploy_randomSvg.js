
const { network } = require('hardhat')
let { networkConfig } = require('../helper-hardhat-config')

module.exports = async({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const {deploy, get, log } = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = await getChainId()

   // if we are on a local chain like Hardhat, what is LINK token address?
   //   A: There is none.
   // Soln: we deploy a fake LINK token
   // but for real chains, we use real LINK tokens

    let linkTokenAddress, vrfCoordinatorAddress

    if (chainId == 31337) {
    // this means we are on a test chain
    // in local network, _keyHash and _fee variables are not required
        // let linkToken = await get('LinkToken')
        // linkTokenAddress = linkToken.address
        // let vrfCoordinatorMock = await get('VRFCoordinatorMock')
        // vrfCoordinatorAddress = vrfCoordinatorMock.address
        let LinkToken = await deploy('LinkToken', { from: deployer, log: true })
        linkTokenAddress = LinkToken.address
        let VRFCoordinatorMock = await deploy('VRFCoordinatorMock', { 
            from: deployer,
            log: true, 
            args: [LinkToken.address]
        })
        vrfCoordinatorAddress = VRFCoordinatorMock.address
   } else {
        linkTokenAddress = networkConfig[chainId]['linkToken']
        vrfCoordinatorAddress = networkConfig[chainId]['vrfCoordinator']

   }
   const keyHash = networkConfig[chainId]['keyHash']
   const fee = networkConfig[chainId]['fee']
   // args required in the RandomSVG.sol Constructor
   let args = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee]
   log("*********RANDOM********S**V**G******IS******BEING*****GENERATED******")
   const RandomSVG = await deploy('RandomSVG', {
        from: deployer,
        args: args,
        log: true
   })
   log("You have deployed your NFT contract!")
   const networkName = networkConfig[chainId]["name"]
   log(`Verify with: \n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`)

   // fund contract with LINK to call Create at deployment time
   const linkTokenContract = await ethers.getContractFactory("LinkToken")
   const accounts = await hre.ethers.getSigners()
   const signer = accounts[0]
   const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer)
   let fund_tx = await linkToken.transfer(RandomSVG.address, fee)
   await fund_tx.wait(1)
   log("Your contract now has 0.1 LINK tokens")

   // Create an NFT! By calling a random number
   const RandomSVGContract = await ethers.getContractFactory("RandomSVG")
   const randomSVG = new ethers.Contract(RandomSVG.address, RandomSVGContract.interface, signer)

   // Create() function emits an Event
   // This Event has tokenID as an Indexed topic
   let creation_tx = await randomSVG.create({ gasLimit: 280000, value:'10000000000000000' })
   let receipt = await creation_tx.wait(1)

   // Chainlink code produces at the 4th event (index 3) the tokenId
   // If working with other contracts, we need to first check the Events they produce
   let tokenId = receipt.events[3].topics[2]
   log(`You've made your NFT! This is token number ${tokenId.toString()}`)
   log(`Let's wait for the Chainlink node to respond...`)
   if (chainId != 31337) {
       // Actual call to ChainlinkVRF
       // Instead of building subscribers to get Chainlink response, we'll just wait 18secs
        await new Promise( r => setTimeout(r, 300000))
        log(`Now let's finish the mint...`)
        let finish_tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 })
        await finish_tx.wait(1)
        log(`You can view the tokenURI here ${await randomSVG.tokenURI(tokenId)}`)

   } else {
       // In local network, we'll simulate the response of the VRFCoordinator contract
       // function callBackWithRandomness() in VRFCoordinatorMock.sol Chainlink contract
       const VRFCoordinatorMock = await deployments.get("VRFCoordinatorMock")
       vrfCoordinator = await ethers.getContractAt("VRFCoordinatorMock", VRFCoordinatorMock.address, signer)
       let vrf_tx = await vrfCoordinator.callBackWithRandomness(receipt.logs[3].topics[1], 77777, randomSVG.address)
       await vrf_tx.wait(1)

       // Now we pretend the VRFCoordinator took time and responds with a randomNumber
       log("Now let's finish the mint!")
       let finish_tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 })
       await finish_tx.wait(1)
       log(`You can view the tokenURI here: ${await randomSVG.tokenURI(tokenId)}`)

   }

}

module.exports.tags = ['all02','rsvg']