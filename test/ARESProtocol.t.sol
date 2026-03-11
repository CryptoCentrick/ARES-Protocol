// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proposal} from "../src/modules/Proposal.sol";
import {TimeLock} from "../src/modules/TimeLock.sol";
import {DistributeReward} from "../src/modules/DistributeReward.sol";
import {AresProtocol} from "../src/core/AresProtocol.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IRewardDistributor} from "../src/interfaces/IRewardDistributor.sol";
import {IProposalManager} from "../src/interfaces/IProposalManager.sol";
import {ITimeLock} from "../src/interfaces/ITimeLock.sol";

contract AresProtocolTest is Test {

    address constant USDC_ADDR = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IERC20 public usdcAddr;

    Proposal public proposal;
    TimeLock public timeLock;
    DistributeReward public rewardDistributor;
    AresProtocol public treasury;

    address public samuel;
    address public mark;
    address public marvel;

    uint256 public signer1Key = 0x111;
    uint256 public signer2Key = 0x222;
    address public signer1;
    address public signer2;

    bytes32 public merkleRoot;
    uint256 public samuelAmount = 100e6;

    function setUp() public {
        vm.createSelectFork("https://0xrpc.io/eth");

        usdcAddr = IERC20(USDC_ADDR);
        samuel = makeAddr("samuel");
        mark = makeAddr("mark");
        marvel = makeAddr("marvel");
        signer1 = vm.addr(signer1Key);
        signer2 = vm.addr(signer2Key);

        vm.startPrank(samuel);

        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        proposal  = new Proposal(signers, 2);
        merkleRoot  = keccak256(abi.encodePacked(samuel, samuelAmount));
        treasury    = new AresProtocol(address(proposal), address(0), address(usdcAddr));
        timeLock    = new TimeLock(address(proposal), address(treasury), 10_000e6);
        rewardDistributor = new DistributeReward(address(usdcAddr), merkleRoot, address(treasury));

        treasury.setTimelock(address(timeLock));
        vm.stopPrank();

        deal(address(usdcAddr), address(treasury), 500_000e6);
        deal(address(usdcAddr), address(rewardDistributor), 10_000e6);
        vm.deal(samuel, 10 ether);
        vm.deal(mark, 10 ether);
    }

    function test_ProposalLifecycle() public {
        bytes32 proposalId = _createProposal("lifecycle test", 1000e6);

        assertEq(
            uint256(_getStatus(proposalId)),
            uint256(IProposalManager.ProposalStatus.PENDING)
        );

        vm.warp(block.timestamp + 1 hours + 1);
        _queueProposal(proposalId);

        assertEq(
            uint256(_getStatus(proposalId)),
            uint256(IProposalManager.ProposalStatus.QUEUED)
        );

        timeLock.queueProposal(proposalId);

        vm.warp(block.timestamp + 24 hours + 1);

        uint256 before = usdcAddr.balanceOf(samuel);
        timeLock.executeProposal(proposalId);
        assertEq(usdcAddr.balanceOf(samuel) - before, 1000e6);

        assertEq(
            uint256(timeLock.getTimeLockEntry(proposalId).timeLockStatus),
            uint256(ITimeLock.TimeLockedStatus.EXECUTED)
        );
    }

    function test_SignatureVerification() public {
        bytes32 proposalId = _createProposal("sig test", 500e6);
        vm.warp(block.timestamp + 1 hours + 1);
        _queueProposal(proposalId);
        assertEq(
            uint256(_getStatus(proposalId)),
            uint256(IProposalManager.ProposalStatus.QUEUED)
        );
    }

    function test_TimelockExecution() public {
        bytes32 proposalId = _createAndQueueToTimelock();

        assertFalse(timeLock.readyToExecute(proposalId));

        vm.warp(block.timestamp + 24 hours + 1);
        assertTrue(timeLock.readyToExecute(proposalId));

        timeLock.executeProposal(proposalId);

        assertEq(
            uint256(timeLock.getTimeLockEntry(proposalId).timeLockStatus),
            uint256(ITimeLock.TimeLockedStatus.EXECUTED)
        );
    }

    function test_RewardClaiming() public {
        bytes32[] memory proof = new bytes32[](0);
        uint256 before = usdcAddr.balanceOf(samuel);

        vm.prank(samuel);
        rewardDistributor.claimReward(samuel, samuelAmount, proof);

        assertEq(usdcAddr.balanceOf(samuel) - before, samuelAmount);
        assertTrue(rewardDistributor.hasClaimed(samuel));
    }

    function test_RevertWhen_Reentrancy() public {
        bytes32 proposalId = _createAndQueueToTimelock();
        vm.warp(block.timestamp + 24 hours + 1);

        timeLock.executeProposal(proposalId);

        vm.expectRevert("not queued");
        timeLock.executeProposal(proposalId);
    }

    function test_RevertWhen_DoubleClaim() public {
        bytes32[] memory proof = new bytes32[](0);

        vm.prank(samuel);
        rewardDistributor.claimReward(samuel, samuelAmount, proof);

        vm.prank(samuel);
        vm.expectRevert("already claimed");
        rewardDistributor.claimReward(samuel, samuelAmount, proof);
    }

    function test_RevertWhen_InvalidSignature() public {
        bytes32 proposalId = _createProposal("invalid sig", 500e6);
        vm.warp(block.timestamp + 1 hours + 1);

        uint256 deadline = block.timestamp + 1 hours;
        uint256 wrongKey = 0xDEAD;

        address[] memory signers    = new address[](2);
        bytes[]   memory signatures = new bytes[](2);
        uint256[] memory nonces     = new uint256[](2);

        signers[0]    = vm.addr(wrongKey);
        signers[1]    = vm.addr(wrongKey);
        signatures[0] = _signProposal(proposalId, wrongKey, signer1, 0, deadline);
        signatures[1] = _signProposal(proposalId, wrongKey, signer2, 0, deadline);

        vm.expectRevert("insufficient signatures");
        proposal.queueProposal(
            proposalId, signers, signatures, nonces, deadline
        );
    }

    function test_RevertWhen_PrematureExecution() public {
        bytes32 proposalId = _createAndQueueToTimelock();

        vm.expectRevert("delay not passed");
        timeLock.executeProposal(proposalId);
    }

    function test_RevertWhen_ProposalReplay() public {
        bytes32 proposalId = _createAndQueueToTimelock();
        vm.warp(block.timestamp + 24 hours + 1);

        timeLock.executeProposal(proposalId);

        vm.expectRevert("not queued");
        timeLock.executeProposal(proposalId);
    }

    function test_RevertWhen_PrematureQueue() public {
        bytes32 proposalId = _createProposal("premature queue", 500e6);

        uint256 deadline = block.timestamp + 1 hours;

        address[] memory signers    = new address[](2);
        bytes[]   memory signatures = new bytes[](2);
        uint256[] memory nonces     = new uint256[](2);

        signers[0]    = signer1;
        signers[1]    = signer2;
        signatures[0] = _signProposal(proposalId, signer1Key, signer1, 0, deadline);
        signatures[1] = _signProposal(proposalId, signer2Key, signer2, 0, deadline);

        vm.expectRevert("still in commit phase");
        proposal.queueProposal(
            proposalId, signers, signatures, nonces, deadline
        );
    }

    function test_RevertWhen_UnauthorizedCancel() public {
        bytes32 proposalId = _createProposal("cancel test", 500e6);

        vm.prank(marvel);
        vm.expectRevert("not authorized to cancel");
        proposal.cancelProposal(proposalId);
    }

    function test_RevertWhen_InvalidMerkleProof() public {
        bytes32[] memory proof = new bytes32[](0);

        vm.prank(samuel);
        vm.expectRevert("invalid proof");
        rewardDistributor.claimReward(samuel, samuelAmount * 2, proof);
    }


    function _createProposal(
        string memory _desc,
        uint256 _amount
    ) internal returns (bytes32) {
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)", samuel, _amount
        );
        vm.prank(mark);
        return proposal.createProposal{value: 1 ether}(
            address(usdcAddr),
            data,
            0,
            _desc,
            IProposalManager.ProposalStatus.TRANSFER
        );
    }

    function _createAndQueueToTimelock() internal returns (bytes32) {
        bytes32 proposalId = _createProposal("timelock test", 1000e6);
        vm.warp(block.timestamp + 1 hours + 1);
        _queueProposal(proposalId);
        timeLock.queueProposal(proposalId);
        return proposalId;
    }

    function _queueProposal(bytes32 _proposalId) internal {
        uint256 deadline = block.timestamp + 1 hours;

        address[] memory signers    = new address[](2);
        bytes[]   memory signatures = new bytes[](2);
        uint256[] memory nonces     = new uint256[](2);

        signers[0]    = signer1;
        signers[1]    = signer2;
        signatures[0] = _signProposal(_proposalId, signer1Key, signer1, 0, deadline);
        signatures[1] = _signProposal(_proposalId, signer2Key, signer2, 0, deadline);

        proposal.queueProposal(_proposalId, signers, signatures, nonces, deadline);
    }

    function _getStatus(
        bytes32 _proposalId
    ) internal view returns (IProposalManager.ProposalStatus) {
        return proposal.getProposalById(_proposalId).state;
    }

    function _signProposal(
        bytes32 _proposalId,
        uint256 _privKey,
        address _signer,      // <-- add this
        uint256 _nonce,
        uint256 _deadline
    ) internal view returns (bytes memory) {

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint chainId,address verifyingContract)"),
                //                                              ^^^^ NOT uint256
                keccak256(bytes("ARES Protocol")),
                keccak256(bytes("1")),
                block.chainid,
                address(proposal)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Approval(bytes32 proposalId,address signer,uint nonce,uint deadline)"),
                //                                     ^^^^^^^^^^^^^^ added, and uint not uint256
                _proposalId,
                _signer,      // <-- added
                _nonce,
                _deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
