// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRewardDistributor} from "../interfaces/IRewardDistributor.sol";
import {IERC20} from "../interfaces/IERC20.sol";

    contract DistributeReward is IRewardDistributor {

    IERC20 private _token;
    bytes32 private _merkleRoot;
    address private _governanceAddress;
    mapping(address => bool) private _claimed;

    constructor(address _tokenAddress, bytes32 _initialRoot, address _governance) {
        _token = IERC20(_tokenAddress);
        _merkleRoot = _initialRoot;
        _governanceAddress = _governance;
    }

    function claimReward(
        address _recipient,
        uint256 _amount,
        bytes32[] calldata _proof
    ) external override {
        require(!_claimed[_recipient], "already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _amount));
        require(_verify(_proof, _merkleRoot, leaf), "invalid proof");
        _claimed[_recipient] = true;
        (bool success) = _token.transfer(_recipient, _amount);
        require(success, "failed to claim");
        emit RewardClaimed(_recipient, _amount);
    }

    function updateRoot(bytes32 _newRoot) external override {
        require(msg.sender == _governanceAddress, "only governance");
        _merkleRoot = _newRoot;
    }

    function distributeReward(address account, uint amount) external override {
        require(msg.sender == _governanceAddress, "only governance");
        bool success = _token.transfer(account, amount);
        require(success, "failed to distribute");
        emit RewardDistributed(account, amount);
    }

    function isClaimed(uint index) external view override returns (bool) {
        return _claimed[address(uint160(index))];
    }

    function hasClaimed(address _recipient) external view returns (bool) {
        return _claimed[_recipient];
    }

    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function _verify(
        bytes32[] calldata _proof,
        bytes32 _root,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash_ = _leaf;
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if (computedHash_ <= proofElement) {
                computedHash_ = keccak256(abi.encodePacked(computedHash_, proofElement));
            } else {
                computedHash_ = keccak256(abi.encodePacked(proofElement, computedHash_));
            }
        }
        return computedHash_ == _root;
    }
}
