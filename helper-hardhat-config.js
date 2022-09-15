const { ethers } = require("hardhat");

const networkConfig = {
	5: {
		name: "goerli",
		vrfCoordinatorAddress: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
		entranceFee: ethers.utils.parseEther("0.01"),
		gasLane:
			"0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
		subscriptionId: "1560",
		callbackGasLimit: "500000",
		interval: "30",
	},

	31337: {
		name: "localhost",
		entranceFee: ethers.utils.parseEther("0.01"),
		gasLane:
			"0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
		callbackGasLimit: "500000",
		interval: "30",
	},
};

const BASE_FEE = ethers.utils.parseEther("0.25");
const GAS_PRICE_LINK = 1e9;
const VERIFICATION_BLOCK_CONFIRMATIONS = 6;

module.exports = {
	networkConfig,
	BASE_FEE,
	GAS_PRICE_LINK,
	VERIFICATION_BLOCK_CONFIRMATIONS,
};
