// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library AttackGuard {

    struct Snapshot {

        mapping(bytes32 => uint) proposalSnapshot;

        mapping(address => mapping(uint => uint)) balanceSnapshot;
    }

    struct RateLimit {
        uint startWindow;
        uint spentToday;
        uint maxDailyAllowance;
    }

    function applymaxdailyAllowance(
        RateLimit storage _self,
        uint _amount
    ) internal {
        if (block.timestamp > _self.startWindow + 1 days) {
            _self.startWindow = block.timestamp;
            _self.spentToday = 0;
        }

        require(
            _self.spentToday + _amount <= _self.maxDailyAllowance,
            "daily limit exceeded"
        );

        _self.spentToday += _amount;
    }

    function isWithinmaxdailyAllowance(
        RateLimit storage _self,
        uint _amount
    ) internal view returns (bool) {
        if (block.timestamp > _self.startWindow + 1 days) {
            return _amount <= _self.maxDailyAllowance;
        }
        return _self.spentToday + _amount <= _self.maxDailyAllowance;
    }

    function logSnapshot(
        Snapshot storage _self,
        bytes32 _proposalId
    ) internal {
        _self.proposalSnapshot[_proposalId] = block.number;
    }

    function logBalance(
        Snapshot storage _self,
        address _user,
        uint _balance
    ) internal {
        _self.balanceSnapshot[_user][block.number] = _balance;
    }


    function getVotingPower(
        Snapshot storage _self,
        address _user,
        bytes32 _proposalId
    ) internal view returns (uint) {
        uint snapshotBlock = _self.proposalSnapshot[_proposalId];
        return _self.balanceSnapshot[_user][snapshotBlock];
    }
}