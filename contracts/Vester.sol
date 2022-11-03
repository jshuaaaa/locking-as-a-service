
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


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
    //Events
    event StreamCreated(uint256 streamId);
    // Functions
    function createStream(address tokenAddress, address user, uint256 startTime, uint256 endTime, uint256 depositAmount) public {
        uint256 streamId = nextStreamId;
        nextStreamId = nextStreamId + 1;
        uint duration = (endTime - startTime);
        uint ratesPerSecond = (depositAmount / duration);
        streams[streamId] = Stream({
            streamId: streamId,
            user: user,
            sender: msg.sender,
            depositAmount: depositAmount,
            startTime: startTime,
            endTime: endTime,
            tokenAddress: tokenAddress,
            ratesPerSecond: ratesPerSecond
        });
        emit StreamCreated(streamId);  
    }
    
    function withdrawFromVest() public {}

    // View functions

    function timePassed(uint256 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];
        if(block.timestamp <= stream.startTime) return 0;
        if(block.timestamp < stream.endTime) return block.timestamp - stream.startTime;
        return stream.endTime - stream.startTime;
    }

    function redeemableBalance(uint256 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];
        uint timePassed = timePassed(streamId);
        return (stream.ratesPerSecond * timePassed);
    }

    function viewNextStreamId() public view returns (uint256) {
        return nextStreamId;
    }

    function viewStream(uint256 streamId) public view returns (
        address user,
        address sender,
        uint256 depositAmount,
        uint256 startTime,
        uint256 endTime,
        address tokenAddress,
        uint256 ratesPerSecond) {
        
        user = streams[streamId].user;
        sender = streams[streamId].sender;
        depositAmount = streams[streamId].depositAmount;
        startTime = streams[streamId].startTime;
        endTime = streams[streamId].endTime;
        tokenAddress = streams[streamId].tokenAddress;
        ratesPerSecond = streams[streamId].ratesPerSecond;
    }


}
