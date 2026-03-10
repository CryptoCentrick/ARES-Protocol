//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library SigAuth {

    bytes32 public constant APPROVAL_TYPEHASH = keccak256(
        "Approval(bytes32 proposalId,address signer,uint nonce,uint deadline)"
    );


    function getDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string _name, string version, uint chainId, address verifyingContract)"),
            keccak256("ARES Protocol"),
            keccak256("1"),
            block.chainid,     
            address(this)      
        ));
    }

    function getStructHash(
        bytes32 proposalId_,
        address signer_,
        uint nonce_,
        uint deadline_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            APPROVAL_TYPEHASH,
            proposalId_,
            signer_,
            nonce_,
            deadline_
        ));
    }

    function getDigest(
        bytes32 proposalId_,
        address signer_,
        uint nonce_,
        uint deadline_
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            getDomainSeparator(),
            getStructHash(proposalId_, signer_, nonce_, deadline_)
        ));
    }

    function recoverSigner(
        bytes32 proposalId_,
        address expectedSigner_,
        uint nonce_,
        uint deadline_,
        bytes memory signature
    ) internal view returns (address) {
        require(signature.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }


        require(
            uint(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid s value"
        );

        require(v == 27 || v == 28, "invalid v value");

        bytes32 digest = getDigest(proposalId_, expectedSigner_, nonce_, deadline_);

        address recovered = ecrecover(digest, v, r, s);
        require(recovered != address(0), "invalid signature");

        return recovered;
    }

    function verifyThreshold(
        bytes32 proposalId_,
        address[] calldata signers_,
        bytes[] calldata signatures_,
        uint[] calldata signerNonces_,
        uint deadline_,
        uint threshold_
    ) internal view returns (bool) {
        require(block.timestamp <= deadline_, "signatures expired");
        require(signers_.length == signatures_.length, "length mismatch");

        uint validCount = 0;

        for (uint i = 0; i < signers_.length; i++) {
            address recovered = recoverSigner(
                proposalId_,
                signers_[i],
                signerNonces_[i],
                deadline_,
                signatures_[i]
            );

            if (recovered == signers_[i]) {
                validCount++;
            }
        }

        return validCount >= threshold_;
    }
}
