// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions

// external & public view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle Contrac
 * @author Odeyemi Michael
 * @notice This conract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle_NotEnoughFeeToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    // @dev The duration of the lottery in seconds
    bytes32 private immutable i_keyhash;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player); // meaning a new player has enter the raffle
    event WinnerPicked(address indexed Winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 gasLane,
        uint256 subscriptionId,
        address vrfCoordinator,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyhash = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        /**
         * require(msg.value >= i_entranceFee, "NotEnoughFeeToEnterRaffle!");
         * The require above is not gas efficient as we are storing in strings
         *
         * require(msg.value >= i_entranceFee, NotEnoughFeeToEnterRaffle()
         * The require can't be used as it is for version 0.8.26 and it require specific compiler version
         *
         */
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughFeeToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender)); // // this will be added/push to our s_players array
        emit RaffleEntered(msg.sender);
        // this will emit the event and anytime you update storage you neeed to emit the event
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING_WINNER;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                // VRFV2PlusClient is the contract while RandomWordsRequest is the struct in the contract
                keyHash: i_keyhash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        // This will wipe all the other players that has entered the raffle already  to 0
        s_lastTimeStamp = block.timestamp;
        // Our time interval will restart

        (bool sucess, ) = recentWinner.call{value: address(this).balance}("");
        if (!sucess) {
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    /**
     * Getter Function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
