
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


error StreamExists();
error WithdrawAmountToLarge();
error NotYourStream();
error RedeemableBalanceIsLowerThenAmount();
error AmountIsZero();
error StartTimePassed();
error DepositAmountTooLow();
error ContractCantBeUser();


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
    event WithdrawFromStream(uint256 streamId, address user, uint256 amount);
    // Functions
    function createStream(address tokenAddress, address user, uint256 startTime, uint256 endTime, uint256 depositAmount) public {
        if(block.timestamp < startTime) revert StartTimePassed();
        if(depositAmount <= 0) revert DepositAmountTooLow();
        if(user == address(this)) revert ContractCantBeUser();
        
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
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), depositAmount);
    }
    
    function withdrawFromStream(uint256 streamId, uint amount) public {
        Stream memory stream = streams[streamId];
        if(msg.sender != stream.user) revert NotYourStream();
        uint256 balance = redeemableBalance(streamId);
        if(amount > balance) revert RedeemableBalanceIsLowerThenAmount();
        if(amount <= 0) revert AmountIsZero();

        IERC20(stream.tokenAddress).transfer(stream.user, amount);
        emit WithdrawFromStream(streamId, stream.user, amount);



    }

    // View functions

    function timePassed(uint256 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];
        if(block.timestamp <= stream.startTime) return 0;
        if(block.timestamp < stream.endTime) return block.timestamp - stream.startTime;
        return stream.endTime - stream.startTime;
    }

    function redeemableBalance(uint256 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];
        uint _timePassed = timePassed(streamId);
        return (stream.ratesPerSecond * _timePassed);
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
