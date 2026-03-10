//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignatureAuthModule {
    mapping(address => uint) signatureNonces;

    bytes32 public DOMAIN_SEPARATOR;

    function verifySignature(address signer, bytes32 messageHash, bytes memory signature) external returns(bool) {
        address signer(signatureNonces);
        signatureNonces++;
        DOMAIN_SEPARATOR(block.chainid, address(this));
        return true;
    }




}