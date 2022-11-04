//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;

import "./lzApp/NonblockingLzApp.sol";


abstract contract LZMessenger is NonblockingLzApp {
    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        uint16 _count,
        bytes _payload
    );

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}



}