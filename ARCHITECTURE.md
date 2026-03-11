## System Architecture

Think of the Ares Protocol system like a security checkpoint chain. Imagine a valuable package moving through several security gates. Each gate checks something different before the package moves forward. If the package fails one check, the process stops immediately.

In Ares Protocol, the “package” is a treasury action. That action might send funds, interact with another contract, or trigger some important operation. The system does not allow funds to move freely. Instead, every action must pass through a strict pipeline of checks.

Here is the flow in simple terms.

User
↓
Proposal Manager
↓
Signature Authorization
↓
Timelock
↓
AresProtocol Treasury
↓
Target Contract

Every stage verifies something different. If any step fails, the proposal stops and nothing happens. No shortcuts exist. No step gets skipped.

This layered design reduces risk. Even if one part fails, the other layers still protect the treasury.

---

### Proposal Manager

Everything begins with a proposal.

A user creates a proposal describing what action the treasury should take. For example, the proposal might request sending funds to a partner contract or distributing rewards.

The Proposal Manager contract stores this information. It keeps track of several important pieces of data:

* proposal identifier
* proposal creator
* timestamp when the proposal started
* encoded transaction data
* current proposal status

When someone submits a proposal, the system places it into a commit phase. This phase lasts one hour. During this time the proposal cannot move forward.

Why does this delay exist?

Because it prevents rushed decisions. Governance signers need time to review what the proposal does before approving it.

The Proposal Manager also tracks the proposal lifecycle. A proposal moves through different states:

PENDING → ACTIVE → QUEUED → EXECUTED or CANCELED

The contract itself does not control funds. It also does not execute transactions. Its only job is to track proposals and enforce the governance process.

---

### Signature Authorization

After the commit phase ends, the proposal needs approval from governance signers.

This is where the SignatureAuth system enters.

Instead of forcing every signer to submit a transaction on-chain, signers approve proposals off-chain using cryptographic signatures. The system uses an EIP-712 structured signature format. This method makes signatures easier to verify and prevents replay attacks.

Each signature contains:

* proposal identifier
* signer address
* signer nonce
* expiration deadline

The contract reconstructs the signed message and recovers the signer’s address using the ECDSA algorithm.

If the recovered address matches a registered signer, the approval counts as valid.

The system follows an M-of-N approval rule. That means a proposal needs a minimum number of valid signer approvals before it can continue.

For example, if the system requires 3 approvals out of 5 signers, then at least three valid signatures must exist before the proposal moves forward.

This design prevents a single signer from controlling the treasury.

---

### Timelock

Once the proposal receives enough approvals, the system places it into the timelock.

The timelock is another security delay. In this system the delay lasts 48 hours.

This stage exists for an important reason. Even if a proposal passes governance approval, the community still needs time to react.

If someone notices a malicious or dangerous proposal during this delay, the system still has time to cancel it.

The TimelockEngine contract records a timestamp when the proposal becomes executable. Until that time arrives, execution fails automatically.

The timelock also includes rate limiting through the AttackGuard library. This feature prevents the treasury from sending too much value within a single day.

If the system detects spending above the allowed daily limit, the transaction fails.

This prevents sudden treasury draining even if a malicious proposal somehow passes governance.

---

### AresProtocol Treasury

The AresProtocol contract acts as the treasury vault.

Think of it as the secure vault where all protocol funds live.

This contract has a simple rule. Only the timelock contract can instruct it to execute transactions. No other contract or user has permission.

The treasury does not know anything about proposals, signers, or governance votes. It simply verifies the caller.

If the caller equals the registered timelock contract, the treasury executes the encoded transaction.

If the caller is anyone else, the transaction fails immediately.

This separation keeps the treasury logic simple and reduces attack surface.

---

### Reward Distribution System

The protocol also contains a separate reward distribution system called the Distributor.

This module operates independently from governance.

Instead of storing every reward allocation on-chain, the system stores a Merkle root. A Merkle root represents a large list of reward entries in a compact cryptographic format.

Each user’s reward is part of that list.

To claim rewards, a user submits:

* their address
* the reward amount
* a Merkle proof

The contract verifies the proof against the stored root. If the proof matches, the user receives the tokens.

Once claimed, the system records the claim to prevent duplicate withdrawals.

This approach saves storage and gas costs while still guaranteeing correct reward distribution.

---

### AttackGuard Library

Security features used across the system live inside the AttackGuard library.

Two important protections come from this library.

The first is rate limiting. The system tracks how much value leaves the treasury each day. If a proposal attempts to exceed the daily limit, the execution fails.

The second is snapshot voting power.

When a proposal begins, the system records the block number associated with it. Voting power calculations then use token balances from that exact block.

This prevents users from borrowing tokens temporarily to manipulate voting results.

---

### How Everything Works Together

When you put all these parts together, the system forms a strict execution pipeline.

First, someone creates a proposal.
Then signers approve it with cryptographic signatures.
Next, the proposal enters the timelock delay.
After the delay expires, the timelock triggers the treasury.
Finally, the treasury executes the action.

At no point can someone jump ahead in the process.

Every step must succeed before the next step begins.

This design keeps the treasury secure, predictable, and resistant to rushed or malicious governance actions.
