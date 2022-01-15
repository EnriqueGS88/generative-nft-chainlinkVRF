module.exports = async({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    if (chainId == 31337) {
        log("local network detected! Deploying mock tokens...") // Deploying LinkToken.sol from test folder
        const LinkToken = await deploy('LinkToken', { from: deployer, log: true })
        const VRFCoordinatorMock = await deploy('VRFCoordinatorMock', { 
            from: deployer,
            log: true, 
            args: [LinkToken.address]
        })
        log("Mocks deployed!")
    }
}

module.exports.tags = [ 'all00']