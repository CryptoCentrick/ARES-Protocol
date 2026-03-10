//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    contract MerkleRewardsModule {
        bytes32 public merkleRoot;
        mapping(address => bool) public hasClaimed;

        function setMerkleRoot(bytes32 _merkleRoot) external {
            merkleRoot = _merkleRoot;
        }

        function getMerkleRoot() external view returns (bytes32) {
            return merkleRoot;
        }

        function updateMerkleRoot(bytes32 _newMerkleRoot) external {
            merkleRoot = _newMerkleRoot;
        }

        function claimReward(bytes32[] calldata proof, uint256 amount) external {
            require(!hasClaimed[msg.sender], "Reward already claimed");
            require(verifyProof(proof, keccak256(abi.encodePacked(msg.sender, amount))), "Invalid proof");

            hasClaimed[msg.sender] = true;
            // Logic to transfer reward to msg.sender
        }

        function verifyProof(bytes32[] calldata proof, bytes32 leaf) internal view returns (bool) {
            bytes32 computedHash = leaf;

            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
                } else {
                    computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                }
            }

            return computedHash == merkleRoot;
        }
    }