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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title A Raffle Contrac
 * @author Odeyemi Michael
 * @notice This conract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    error Raffle_NotEnoughFeeToEnterRaffle();
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    // @dev The duration of the lottery in seconds
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    event RaffleEntered(address indexed player); // meaning a new player has enter the raffle

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        /**require(msg.value >= i_entranceFee, "NotEnoughFeeToEnterRaffle!");
         * The require above is not gas efficient as we are storing in strings
         *
         * require(msg.value >= i_entranceFee, NotEnoughFeeToEnterRaffle()
         * The require can't be used as it is for version 0.8.26 and it require specific compiler version
         * */
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughFeeToEnterRaffle();
        }

        s_players.push(payable(msg.sender)); // // this will be added/push to our s_players array
        emit RaffleEntered(msg.sender);
        // this will emit the event and anytime you update storage you neeed to emit the event
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
    }

    /**
     * Getter Function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
