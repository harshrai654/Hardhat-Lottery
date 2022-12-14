//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(
	uint256 currentBalance,
	uint256 numPlayers,
	uint256 raffleState
);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
	/**
	 * Type declarations
	 */
	enum RaffleState {
		OPEN,
		CALCULATING
	}

	/**
	 * Storage variables
	 */
	uint256 private immutable i_entranceFee;
	address payable[] private s_players;
	VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
	uint64 private immutable i_subscriptionId;
	bytes32 private immutable i_gasLane;
	uint32 private immutable i_callbackGasLimit;
	uint16 private constant REQUEST_CONFIRMATIONS = 3;
	uint32 private constant NUM_WORDS = 1;
	uint256 private immutable i_interval;
	uint256 private s_lastTimestamp;

	/**
	 * Lottery variables
	 */
	address private s_recentWinner;
	RaffleState private s_raffleState;

	/**
	 * Events
	 */
	event RaffleEnter(address indexed player);
	event RequestedRaffleWinner(uint256 indexed requestId);
	event WinnerPicked(address indexed winner);

	constructor(
		uint256 _entranceFee,
		address _vrfCoordinatorV2, //contract
		uint64 _subscriptionId,
		bytes32 _gasLane, // keyHash
		uint32 _callbackGasLimit,
		uint256 _interval
	) VRFConsumerBaseV2(_vrfCoordinatorV2) {
		i_entranceFee = _entranceFee;
		i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
		i_subscriptionId = _subscriptionId;
		i_gasLane = _gasLane;
		i_callbackGasLimit = _callbackGasLimit;
		s_raffleState = RaffleState.OPEN;
		s_lastTimestamp = block.timestamp;
		i_interval = _interval;
	}

	function enterRaffle() public payable {
		if (msg.value < i_entranceFee) {
			revert Raffle__NotEnoughEthEntered();
		}

		if (s_raffleState != RaffleState.OPEN) {
			revert Raffle__NotOpen();
		}
		s_players.push(payable(msg.sender));
		emit RaffleEnter(msg.sender);
	}

	function performUpkeep(
		bytes calldata /*performData*/
	) external override {
		(bool upkeepNeeded, ) = checkUpkeep("");

		if (!upkeepNeeded) {
			revert Raffle__UpkeepNotNeeded(
				address(this).balance,
				s_players.length,
				uint256(s_raffleState)
			);
		}

		s_raffleState = RaffleState.CALCULATING;
		uint256 requestId = i_vrfCoordinator.requestRandomWords(
			i_gasLane,
			i_subscriptionId,
			REQUEST_CONFIRMATIONS,
			i_callbackGasLimit,
			NUM_WORDS
		);

		emit RequestedRaffleWinner(requestId);
	}

	function fulfillRandomWords(
		uint256, /* requestId */
		uint256[] memory randomWords
	) internal override {
		uint256 winnerIndex = randomWords[0] % s_players.length;
		address payable winner = s_players[winnerIndex];
		s_recentWinner = winner;
		s_raffleState = RaffleState.OPEN;
		s_players = new address payable[](0);
		s_lastTimestamp = block.timestamp;

		(bool success, ) = winner.call{value: address(this).balance}("");
		if (!success) {
			revert Raffle__TransferFailed();
		}

		emit WinnerPicked(winner);
	}

	function checkUpkeep(
		bytes memory /*checkData*/
	)
		public
		view
		override
		returns (
			bool upkeepNeeded,
			bytes memory /*performData*/
		)
	{
		bool isOpen = s_raffleState == RaffleState.OPEN;
		bool timePassed = block.timestamp - s_lastTimestamp > i_interval;
		bool hasPlayers = s_players.length > 0;
		bool hasBalance = address(this).balance > 0;

		upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;

		return (upkeepNeeded, "0x0");
	}

	/**
	 * View/Pure functions
	 */
	function getEntranceFee() public view returns (uint256) {
		return i_entranceFee;
	}

	function getPlayer(uint256 _index) public view returns (address) {
		return s_players[_index];
	}

	function getRecentWinner() public view returns (address) {
		return s_recentWinner;
	}

	function getRaffleState() public view returns (RaffleState) {
		return s_raffleState;
	}

	function getNumWords() public pure returns (uint32) {
		return NUM_WORDS;
	}

	function getNumPlayers() public view returns (uint256) {
		return s_players.length;
	}

	function getLatestTimestamp() public view returns (uint256) {
		return s_lastTimestamp;
	}

	function getRequestConfirmations() public pure returns (uint16) {
		return REQUEST_CONFIRMATIONS;
	}
}
