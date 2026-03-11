//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProposalManager {
   
    enum ProposalStatus {
        TRANSFER,
        CALL,
        UPGRADE,
        PENDING,
        QUEUED,
        EXECUTED,
        CANCELED
    }

    struct Proposal {
        address target;
        address proposer;
        bytes data;
        ProposalStatus state;
        string desc;
        uint value;
        uint timeCreated;
}

    event ProposalCreated(bytes32 indexed proposalId, ProposalStatus indexed state);
    event ProposalExecuted(bytes32 indexed proposalId, ProposalStatus indexed state);
    event ProposalQueued(bytes32 indexed proposalId, ProposalStatus indexed state);
    event ProposalCanceled(bytes32 indexed proposalId, ProposalStatus indexed state);

    function createProposal(address _target, bytes calldata _data, uint _value, string memory _desc, ProposalStatus state) external payable returns (bytes32);

    function getProposalById(bytes32 _proposalId) external returns (Proposal memory);

    function queueProposal(bytes32 _proposalId) external;

    function cancelProposal(bytes32 _proposalId) external;

    function readyToQueue(bytes32 _proposalId) external view returns (bool);
}