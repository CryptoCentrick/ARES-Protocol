//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ITimeLockEngine {
    
    enum TimeLockedStatus {
        QUEUED,
        EXECUTED,
        CANCELED
    }

    struct TimeLocked {
        bytes32 proposalId;
        uint startedAt;
        TimeLockedStatus timeLockStatus;
    }

    event TimeLockedQueued(bytes32 indexed proposalId, uint startedAt);
    event TimeLockedExecuted(bytes32 indexed proposalId, uint startedAt);
    event TimeLockedCanceled(bytes32 indexed proposalId, uint startedAt);

    function getTimestamp(bytes32 _proposalId) external view returns (uint);

    function queueProposal(bytes32 _proposalId) external;

    function executeProposal(bytes32 _proposalId) external;

    function cancelProposal(bytes32 _proposalId) external;

    function getTimelockStatus(bytes32 _proposalId) external;

    function readyToExecute(bytes32 _proposalId) external view returns (bool);
}