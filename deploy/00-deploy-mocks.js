const {
	networkConfig,
	BASE_FEE,
	GAS_PRICE_LINK,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();
	const chainId = network.config.chainId;

	if (!networkConfig[chainId].vrfCoordinatorAddress) {
		log("Local Network Detected! Deploying Mocks...");
		await deploy("VRFCoordinatorV2Mock", {
			from: deployer,
			log: true,
			args: [BASE_FEE, GAS_PRICE_LINK],
		});

		log("Mocks deployed!");
		log("---------------------------------");
	}
};

module.exports.tags = ["all", "mocks"];
