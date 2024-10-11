// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Raffle} from "src/Raffle.sol";
import {FundSubscription, CreateSubscription} from "script/Interactions.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "script/DeployRaffle.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract RaffleIntergration is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    address linkToken;
    address account;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testIfFundSubscriptionIsWorkingWell() public {
        CreateSubscription createSubscription = new CreateSubscription();
        createSubscription.createSubscriptions(address(vrfCoordinator), address(account));

        assert(address(raffle).balance == 0);
    }
}
