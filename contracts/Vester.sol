
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lzApp/NonblockingLzApp.sol";

error EndTimeNotCompatible();
error WithdrawAmountToLarge();
error NotYourStream();
error RedeemableBalanceIsLowerThenAmount();
error AmountIsZero();
error StartTimePassed();
error DepositAmountTooLow();
error ContractCantBeUser();
error StreamDoesntExist();
error NoTokensLeft();
error RateCantBeZero();

contract Vester is NonblockingLzApp {
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
        uint256 balance;
        bool active;
    }

    mapping(uint256 => Stream) private streams;


    //Events
    event StreamCreated(uint256 streamId);
    event WithdrawFromStream(uint256 streamId, address user, uint256 amount);
    event MessageRecieved(uint streamId);


    // Modifiers
    modifier StreamExists(uint256 streamId) {
        if(!streams[streamId].active) revert StreamDoesntExist();
        _;
    }
    
    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}
    
    // Functions
    function createStream(address tokenAddress, address user, uint256 startTime, uint256 endTime, uint256 depositAmount) public {
        if(block.timestamp < startTime) revert StartTimePassed();
        if(depositAmount <= 0) revert DepositAmountTooLow();
        if(user == address(this)) revert ContractCantBeUser();
        
        uint256 streamId = nextStreamId;
        nextStreamId = nextStreamId + 1;
        uint duration = (endTime - startTime);
        if(duration > depositAmount) revert RateCantBeZero();
        if(depositAmount % duration != 0) revert EndTimeNotCompatible();
        uint ratesPerSecond = (depositAmount / duration);
        streams[streamId] = Stream({
            streamId: streamId,
            user: user,
            sender: msg.sender,
            depositAmount: depositAmount,
            startTime: startTime,
            endTime: endTime,
            tokenAddress: tokenAddress,
            ratesPerSecond: ratesPerSecond,
            balance: depositAmount,
            active: true
        });
        emit StreamCreated(streamId);  
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), depositAmount);
    }
    
    function withdrawFromStream(uint256 streamId, uint amount) StreamExists(streamId) public {
        Stream memory stream = streams[streamId];
        if(msg.sender != stream.user) revert NotYourStream();
        uint256 balance = redeemableBalance(streamId);
        if(amount > balance) revert RedeemableBalanceIsLowerThenAmount();
        if(amount <= 0) revert AmountIsZero();

        if(stream.balance == 0) {
            delete streams[streamId];
            revert NoTokensLeft();
        }

        streams[streamId].balance = (stream.depositAmount - amount);
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

    function viewStream(uint256 streamId) StreamExists(streamId) public view returns (
        address user,
        address sender,
        uint256 depositAmount,
        uint256 startTime,
        uint256 endTime,
        address tokenAddress,
        uint256 ratesPerSecond,
        uint256 balance,
        bool active) {
        
        user = streams[streamId].user;
        sender = streams[streamId].sender;
        depositAmount = streams[streamId].depositAmount;
        startTime = streams[streamId].startTime;
        endTime = streams[streamId].endTime;
        tokenAddress = streams[streamId].tokenAddress;
        ratesPerSecond = streams[streamId].ratesPerSecond;
        balance = streams[streamId].balance;
        active = streams[streamId].active;
    }

    function sendMessage(uint16 _dstChainId, address, uint streamId) public payable {
        bytes memory payload = abi.encode(streamId);
        uint16 version = 1;
        uint gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        _lzSend( // {value: messageFee} will be paid out of this contract!
            _dstChainId, // destination chainId
            payload, // abi.encode()'ed bytes
            payable(address(this)), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send()
            address(0x0), // future param, unused for this example
            adapterParams, // v1 adapterParams, specify custom destination gas qty
            msg.value
        );
    }


    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        // When received a message decode the _payload to get chainId

        uint _chainId = abi.decode(_payload, (uint));
        emit MessageRecieved(_chainId);

        

    }



}
