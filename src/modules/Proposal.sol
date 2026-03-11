//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IProposalManager} from "../interfaces/IProposalManager.sol";
import {SigAuth} from "../libraries/SigAuth.sol";
import {AttackDefender} from "../libraries/AttackDefender.sol";

    contract Proposal is IProposalManager {
        
    mapping(bytes32 => IProposalManager.Proposal) private _proposals;
    mapping(address => uint256) private _nonces;
    mapping(address => bool) private _authorizedSigners;
    mapping(bytes32 => uint256) private _deposits;

    uint256 private _requiredVotes;

    uint256 private constant LOCK_PERIOD = 1 hours;

    uint256 private constant PROPOSAL_FEE = 0.1 ether;

    constructor(address[] memory _signers, uint256 _thresh) {
        require(_thresh > 0, "quorum cannot be zero");
        require(_thresh <= _signers.length, "quorum exceeds signers");

        for (uint256 i = 0; i < _signers.length; i++) {
            _authorizedSigners[_signers[i]] = true;
        }
        _requiredVotes = _thresh;
    }

    function createProposal(
        address _target,
        bytes calldata _data,
        uint _value,
        string memory _desc,
        ProposalStatus state
    ) external payable override returns (bytes32) {
        bytes32 proposalId = keccak256(
            abi.encodePacked(
            msg.sender,
            block.timestamp,
            _target,
            _data,
            _value,
            _desc,
            state
        )
        );

        require(_proposals[proposalId].timeCreated == 0, "proposal already exists");

        _deposits[proposalId] = msg.value;

        _proposals[proposalId] = IProposalManager.Proposal({
            target: _target,
            proposer: msg.sender,
            data: _data,
            state: state,
            desc: _desc,
            value: _value,
            timeCreated: block.timestamp
        });

        emit ProposalCreated(proposalId, state);

        return proposalId;
    }

    function getProposalById(bytes32 _proposalId)
        external view
        override
        returns (IProposalManager.Proposal memory)
    {
        require(_proposals[_proposalId].timeCreated != 0, "proposal does not exist");
        return _proposals[_proposalId];
    }

    function queueProposal(bytes32 _proposalId) external override {
        require(_proposals[_proposalId].timeCreated != 0, "proposal does not exist");

        IProposalManager.Proposal storage proposal = _proposals[_proposalId];

        require(
            proposal.state != ProposalStatus.QUEUED &&
                proposal.state != ProposalStatus.EXECUTED &&
                proposal.state != ProposalStatus.CANCELED,
            "proposal is not pending"
        );

        require(
            block.timestamp >= proposal.timeCreated + LOCK_PERIOD,
            "still in commit phase"
        );

        proposal.state = ProposalStatus.QUEUED;

        emit ProposalQueued(_proposalId, proposal.state);
    }

    function cancelProposal(bytes32 _proposalId) external override {
        require(_proposals[_proposalId].timeCreated != 0, "proposal does not exist");

        IProposalManager.Proposal storage proposal = _proposals[_proposalId];

        require(
            proposal.state != ProposalStatus.EXECUTED &&
                proposal.state != ProposalStatus.CANCELED,
            "proposal cannot be cancelled"
        );

        require(
            proposal.proposer == msg.sender || _authorizedSigners[msg.sender],
            "not authorized to cancel"
        );

        proposal.state = ProposalStatus.CANCELED;

        uint256 deposit = _deposits[_proposalId];
        delete _deposits[_proposalId];

        if (deposit != 0) {
            (bool success, ) = payable(proposal.proposer).call{value: deposit}("");
            require(success, "refund failed");
        }

        emit ProposalCanceled(_proposalId, proposal.state);
    }

    function readyToQueue(bytes32 _proposalId) external view override returns (bool) {
        IProposalManager.Proposal storage proposal = _proposals[_proposalId];
        require(proposal.timeCreated != 0, "proposal does not exist");
        return block.timestamp >= proposal.timeCreated + LOCK_PERIOD;
    }
}
