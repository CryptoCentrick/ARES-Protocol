//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExecutionQueue {

    struct QueuedTx {
        uint id;
        address target;
        uint value;
        bytes data;
        uint executeAfter;
        bool exceuted;
    }

    mapping(uint => QueuedTx) public queuedTxs;
    uint public executionDelay; 

    constructor(uint _executionDelay) {
        executionDelay = _executionDelay;
    }

    function queueTransaction(address target, uint value, bytes calldata data) external {
        uint id = uint(keccak256(abi.encodePacked(target, value, data, block.timestamp)));
        queuedTxs[id] = QueuedTx({
            id: id,
            target: target,
            value: value,
            data: data,
            executeAfter: block.timestamp + executionDelay,
            exceuted: false
        });
    }

    function executeTransaction(uint id) external {
        QueuedTx storage tx = queuedTxs[id];
        require(block.timestamp >= tx.executeAfter, "Transaction cannot be executed yet");
        require(tx.exceuted == false, "Transaction already executed");

        (bool success, ) = tx.target.call{value: tx.value}(tx.data);
        require(success, "Transaction execution failed");

        tx.exceuted = true;
    }
       
       function cancelTransaction(uint id) external {
        QueuedTx storage tx = queuedTxs[id];
        require(block.timestamp < tx.executeAfter, "Transaction already executable");
        require(tx.exceuted == false, "Transaction already executed");

        delete queuedTxs[id];    
}
}