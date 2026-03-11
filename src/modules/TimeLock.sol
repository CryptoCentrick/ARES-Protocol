// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITimeLock} from "../interfaces/ITimeLock.sol";
import {IProposalManager as IProposal} from "../interfaces/IProposalManager.sol";
import {AttackDefender} from "../libraries/AttackDefender.sol";

    abstract contract TimeLock is ITimeLock {

    mapping(bytes32 => ITimeLock.TimeLocked) private _entries;

    IProposal private _proposal;
    address private _treasury;

    uint256 public constant TIMELOCK_DELAY = 48 hours;

    bool private _locked;

    AttackDefender.RateLimit private _rateLimit;

    modifier nonReentrant() {
        require(!_locked, "reentrant call");
        _locked = true;
        _;
        _locked = false;
    }


    constructor(
        address _proposalMgAddr,
        address _treasuryAddr,
        uint256 _maxDailyLimit
    ) {
        _proposal = IProposal(_proposalMgAddr);
        _treasury = _treasuryAddr;


        _rateLimit.maxDailyAllowance = _maxDailyLimit;
        _rateLimit.startWindow = block.timestamp;
        _rateLimit.spentToday = 0;
    }

    function queueProposal(bytes32 _proposalId) external override {
        IProposal.Proposal memory proposal = _proposal.getProposalById(_proposalId);

        require(proposal.timeCreated != 0, "proposal does not exist");

        require(
            proposal.state == IProposal.ProposalStatus.QUEUED,
            "proposal not queued"
        );

        require(_entries[_proposalId].startedAt == 0, "already in timelock");

        _entries[_proposalId] = ITimeLock.TimeLocked({
            proposalId: _proposalId,
            startedAt: block.timestamp + TIMELOCK_DELAY, 
            timeLockStatus: ITimeLock.TimeLockedStatus.QUEUED
        });

        emit TimeLockedQueued(_proposalId, _entries[_proposalId].startedAt);
    }


    function executeProposal(bytes32 _proposalId) external override nonReentrant {
        ITimeLock.TimeLocked storage entry = _entries[_proposalId];

        require(entry.startedAt != 0, "entry does not exist");
        require(entry.timeLockStatus == ITimeLock.TimeLockedStatus.QUEUED, "not queued");
        require(block.timestamp >= entry.startedAt, "delay not passed");

        IProposal.Proposal memory proposal = _proposal.getProposalById(_proposalId);


        AttackDefender.applymaxdailyAllowance(_rateLimit, proposal.value);

        entry.timeLockStatus = ITimeLock.TimeLockedStatus.EXECUTED;

        (bool success, ) = _treasury.call{value: proposal.value}(proposal.data);
        require(success, "execution failed");

        emit TimeLockedExecuted(_proposalId, entry.startedAt);
    }

    function cancelProposal(bytes32 _proposalId) external override {
        ITimeLock.TimeLocked storage entry = _entries[_proposalId];

        require(entry.startedAt != 0, "entry does not exist");
        require(entry.timeLockStatus == ITimeLock.TimeLockedStatus.QUEUED, "not queued");

        entry.timeLockStatus = ITimeLock.TimeLockedStatus.CANCELED;

        emit TimeLockedCanceled(_proposalId, entry.startedAt);
    }

    function getTimestamp(bytes32 _proposalId) external view override returns (uint) {
        require(_entries[_proposalId].startedAt != 0, "entry does not exist");
        return _entries[_proposalId].startedAt;
    }

    function getTimeLockStatus(bytes32 _proposalId) external view {
        require(_entries[_proposalId].startedAt != 0, "entry does not exist");
    }

    function getTimeLockEntry(bytes32 _proposalId) external view returns (ITimeLock.TimeLocked memory) {
        require(_entries[_proposalId].startedAt != 0, "entry does not exist");
        return _entries[_proposalId];
    }

    function readyToExecute(bytes32 _proposalId) external view override returns (bool) {
        ITimeLock.TimeLocked storage entry = _entries[_proposalId];
        return
            entry.startedAt != 0 &&
            entry.timeLockStatus == ITimeLock.TimeLockedStatus.QUEUED &&
            block.timestamp >= entry.startedAt;
    }
}
