
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


error StreamExists();
error WithdrawAmountToLarge();

contract Vester {
    // State variables
    uint256 private nextStreamId = 1;

    struct Stream {
        uint256 streamId;
        address user;
        address sender;
        uint256 depositAmount;
        uint256 startTime;
        uint256 endTime;
        address tokenAddress;
        uint256 ratesPerSecond;
    }

    mapping(uint256 => Stream) private streams;
    
    // Functions
    function createStream(address tokenAddress, address user, uint256 startTime, uint256 endTime, uint256 depositAmount) public returns (uint256) {
        uint256 streamId = nextStreamId;
        nextStreamId = nextStreamId + 1;
        streams[streamId] = Stream({
            streamId: streamId,
            user: user,
            sender: msg.sender,
            depositAmount: depositAmount,
            startTime: startTime,
            endTime: endTime,
            tokenAddress: tokenAddress,
            ratesPerSecond: 100 // temporary number until we implement function to calculate rates per second
        })     
    }

    function withdrawFromVest() public {}

    // View functions


}
