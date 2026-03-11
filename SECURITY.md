## Security Analysis

When you build a system that holds money, the first thing you think about is not features. You think about what could go wrong. Attackers look for the smallest mistake. If they find one weak door, they push it open and take everything.

So the Ares Protocol system treats security like layers of defense. Think of it like a castle. You do not rely on one wall. You build several walls. Even if one layer fails, the next layer still stands.

In this system there are several places where attacks might happen. These are called attack surfaces. Each one has a protection built around it.

Let’s walk through the most important ones.

### Flash Loan Attack

One of the most common tricks in crypto governance uses something called a flash loan.

Here is how that trick works.

An attacker borrows a massive amount of tokens for a single transaction. With those tokens they suddenly gain huge voting power. They push a proposal through governance. After the transaction ends, the borrowed tokens return to the lender.

So the attacker never truly owned the tokens. But for a short moment they controlled the vote.

The system prevents this with a snapshot mechanism.

When a proposal gets created, the protocol records the exact block number at that moment. That block becomes the snapshot point. Voting power always reads token balances from that block.

That means if someone borrows tokens later, those borrowed tokens do not count.

The voting system only sees the balances that existed when the proposal started.

So the flash loan trick stops working.

### Signature Replay Attack

Another attack involves reusing a signature.

Signatures prove that a governance signer approved a proposal. But imagine if someone takes a valid signature and reuses it again later on a different proposal.

Without protection, the system might accept the reused signature.

To prevent this, every signer has a nonce.

A nonce is a simple number that increases each time a signature gets used. When a signature includes a nonce value, the system expects the next unused number.

If someone tries to reuse an old signature, the nonce will not match anymore. The contract rejects it instantly.

That old signature becomes useless forever.

### Cross-Chain Replay Attack

Crypto systems run on many different blockchains. Sometimes a signature created on one chain might still look valid on another chain.

Attackers sometimes exploit this by copying a signature from one network and submitting it somewhere else.

Ares blocks this by embedding the chain ID and the contract address inside the signature structure.

So when a signer approves a message, that message is tied to a specific blockchain and a specific contract.

If the signature appears on another network, the system detects that the chain ID does not match. The verification fails immediately.

This keeps signatures locked to the exact environment where they were created.

### Reentrancy Attack

Reentrancy is one of the most famous smart contract attacks.

It happens when a contract sends funds to another contract, and that receiving contract calls back into the original function before it finishes.

If the original contract does not guard against this, the attacker might repeat the same action multiple times before the system updates its state.

That trick has drained many protocols in the past.

The Ares timelock execution uses two protections to stop this.

The first protection is a nonReentrant lock. When the execute function begins, the contract sets a lock variable. If another call tries to enter the same function while the lock is active, the transaction fails.

The second protection updates the proposal status before the external call happens.

So the system marks the proposal as executed first. Only then does it perform the external treasury call.

Even if a malicious contract tried to call execute again, the proposal status already shows executed. The contract rejects the attempt.

### Treasury Drain Attempt

A more obvious attack involves trying to withdraw everything from the treasury in one proposal.

Imagine someone somehow convinces governance signers to approve a massive withdrawal.

Without limits, the entire treasury could disappear in one transaction.

Ares reduces this risk using a rate limit system.

The protocol tracks how much value leaves the treasury during a twenty four hour window. Every new execution checks the total amount already spent that day.

If the next transaction pushes the total above the allowed limit, the system rejects it.

Even if a malicious proposal gets approved, the attacker cannot drain the whole treasury instantly.

This delay gives the community time to react.

### Proposal Griefing

Another attack does not steal money. Instead it tries to break the governance process itself.

Someone might spam the system with hundreds of useless proposals. This slows down the network and wastes time for governance participants.

To discourage that behavior, creating a proposal requires a deposit.

In this system the deposit equals one ETH.

This cost forces users to think before submitting proposals. If someone tries to spam the system, they lose a lot of money doing it.

Governance also has the power to slash the deposit if the proposal looks malicious or abusive.

So spam proposals become expensive.

### Double Reward Claim

The reward distribution system also has its own risks.

Imagine a contributor claiming their reward once. After the transfer succeeds, they try to claim it again using the same proof.

Without protection, they might receive the same reward multiple times.

The distributor contract solves this with a claim tracker.

Each address has a record in a mapping called claimed.

When a user successfully claims their reward, the contract marks that address as claimed. After that moment, any attempt to claim again fails instantly.

So every reward gets claimed only once.

### Premature Proposal Execution

Another attack might try to execute a proposal too early.

The system includes a timelock delay to give people time to review governance decisions. If someone bypassed this delay, they could push harmful proposals through instantly.

The protocol prevents this by storing a timestamp that defines when the proposal becomes executable.

When the execute function runs, the contract checks the current block time against that timestamp.

If the delay has not passed yet, the execution fails immediately.

So no one can rush the process.

### Final Thoughts

Security in a treasury system is about patience and discipline. The protocol forces every proposal to slow down and pass through multiple checks.

First governance must approve it.
Then the timelock delays it.
Then rate limits restrict withdrawals.
Then execution protections prevent contract tricks.

Each layer reduces risk.

No system is perfect. But when you stack enough protections together, attacking the system becomes extremely difficult.
