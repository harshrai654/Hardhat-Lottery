const { network, ethers } = require("hardhat");
const {
	networkConfig,
	VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("2");

module.exports = async function ({ getNamedAccounts, deployments }) {
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();
	const chainId = network.config.chainId;

	const { entranceFee, gasLane, callbackGasLimit, interval } =
		networkConfig[chainId];
	let vrfCoordinatorAddress, subscriptionId;

	if (networkConfig[chainId].vrfCoordinatorAddress) {
		vrfCoordinatorAddress = networkConfig[chainId].vrfCoordinatorAddress;
		subscriptionId = networkConfig[chainId].subscriptionId;
	} else {
		const vrfCoordinatorV2 = await ethers.getContract(
			"VRFCoordinatorV2Mock"
		);
		vrfCoordinatorAddress = vrfCoordinatorV2.address;
		const transactionResponse = await vrfCoordinatorV2.createSubscription();
		const transactionReceipt = await transactionResponse.wait(1);
		subscriptionId = transactionReceipt.events[0].args.subId;

		//Fund the subscription
		await vrfCoordinatorV2.fundSubscription(
			subscriptionId,
			VRF_SUB_FUND_AMOUNT
		);
	}

	const args = [
		entranceFee,
		vrfCoordinatorAddress,
		subscriptionId,
		gasLane,
		callbackGasLimit,
		interval,
	];

	const raffle = await deploy("Raffle", {
		from: deployer,
		args,
		log: true,
		waitConfirmations: networkConfig[chainId].vrfCoordinatorAddress
			? VERIFICATION_BLOCK_CONFIRMATIONS
			: 1,
	});

	if (networkConfig[chainId].vrfCoordinatorAddress) {
		await verify(raffle.address, args);
	}

	log("---------------------------------");
};

module.exports.tags = ["all", "raffle"];
