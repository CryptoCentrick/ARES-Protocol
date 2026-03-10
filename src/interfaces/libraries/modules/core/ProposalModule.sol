//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalModules {

    event ProposalCreated(uint indexed proposalId, address indexed proposer, address target, uint value, bytes data);
    event ProposalApproved(uint indexed proposalId, address indexed approver);
    event ProposalQueued(uint indexed proposalId, uint executionTime);
    event ProposalExecuted(uint indexed proposalId);
    event ProposalCancelled(uint indexed proposalId);

    struct Proposal {
        uint id;
        address proposer;
        address target;
        uint value;
        bytes data;
        uint createdAt;
        uint executionTime;
        states status;
        uint signatureCount;
    }

    enum states {
       none,
       committed,       
       approved,
       executed,
       queued,
       cancelled
    } 

    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public approvedBy; // proposalId => approver => approved

    uint public proposalCount;
    uint public minApprovals;
    uint public executionDelay;

    constructor(uint _minApprovals, uint _executionDelay) {
        minApprovals = _minApprovals;
        executionDelay = _executionDelay;
    }

    function createProposal(address target, uint value, bytes calldata data) external {
        proposalCount++;
        uint id = proposalCount;
        proposals[proposalCount] = Proposal({
            id: id,
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            createdAt: block.timestamp,
            executionTime: 0,
            status: states.committed,
            signatureCount: 0
        });
        emit ProposalCreated(id, msg.sender, target, value, data);
    }

    function approveProposal(uint proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!approvedBy[proposalId][msg.sender], "Already approved");
        approvedBy[proposalId][msg.sender] = true;
        proposal.signatureCount++;
        if(proposal.signatureCount >= minApprovals) {
            proposal.status = states.approved;
        }
        emit ProposalApproved(proposalId, msg.sender);
    }

    function queueProposal(uint proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        proposal.executionTime = block.timestamp + executionDelay;
        proposal.status = states.queued;
        emit ProposalQueued(proposalId, proposal.executionTime);
    }

    function executedProposal(uint proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == states.queued, "Proposal not queued");
        require(block.timestamp >= proposal.executionTime, "Execution time not reached");

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        proposal.status = states.executed;
        emit ProposalExecuted(proposalId);
    }

    function cancelProposal(uint proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.proposer == msg.sender, "Only proposer can cancel");
        require(proposal.status != states.executed, "Cannot cancel executed proposal");
        proposal.status = states.cancelled;
        delete proposals[proposalId];

        emit ProposalCancelled(proposalId);
    }

    function getProposalStatus(uint proposalId) external view returns (states) {
        Proposal storage proposal = proposals[proposalId];
        
        return proposal.status;
    }
}