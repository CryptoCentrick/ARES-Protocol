## Protocol Specification

Let’s walk through how the ARES Protocol actually works from start to finish. Think of it like a careful checklist the system follows before doing anything important with money.

When a protocol controls a treasury, every action must follow clear rules. If anyone could move funds whenever they wanted, the system would fall apart quickly. That is why ARES uses a structured process. Every proposal moves step by step through the system. Nothing jumps ahead. Nothing skips a stage.

You can picture it like a relay race. One stage finishes its job, then hands the baton to the next stage. Only after the final stage finishes does the action happen.

There are five main stages in this process.

Proposal Creation
Approval
Queueing
Execution
Cancellation

Let’s go through them one by one.

### Proposal Creation

Everything begins with someone submitting a proposal.

A proposal is basically an instruction the protocol might carry out later. For example, a proposal might request that the treasury sends funds to another contract. It might update some parameter in the system. Or it might trigger a reward distribution.

To create a proposal, a user provides several important pieces of information. These include the target address the system will interact with, the data describing which function should run, and the value that might be transferred along with the call.

Think of it like writing a command the protocol will follow later.

But the proposal does not execute immediately. First it must pass through several checks.

There is also a small deposit required when submitting a proposal. This deposit helps stop spam. Without a cost, someone could flood the system with thousands of meaningless proposals. By requiring a deposit, the protocol makes sure people think before submitting something.

Once the proposal enters the system, it receives an identifier and the protocol records the time it was created.

At this point the proposal exists, but nothing else happens yet.

### Approval

After a proposal gets created, the next stage involves governance signers.

These signers act like trusted reviewers. Their job is to look at proposals and decide whether they should move forward.

Instead of requiring each signer to submit an on-chain transaction, the protocol uses cryptographic signatures. Each signer reviews the proposal off-chain and signs a message if they approve it.

These signatures follow a structured format based on the EIP-712 standard. This format includes important information such as the proposal identifier, the signer’s address, a nonce value, and an expiration deadline.

When the signatures get submitted to the contract, the system verifies them. It reconstructs the signed message and checks whether the signature truly came from the expected signer.

A proposal does not move forward with just one approval. The protocol requires a minimum number of approvals, often called an M-of-N threshold. That means a specific number of signers must agree before the proposal continues.

This rule prevents a single signer from controlling the system.

Once enough valid signatures exist, the proposal becomes eligible for the next stage.

### Queueing

After approval, the proposal moves into the timelock queue.

This is where the system introduces a waiting period.

When a proposal enters the queue, the protocol records a timestamp representing when the proposal becomes executable. Until that time arrives, the proposal cannot run.

In ARES Protocol this delay lasts forty-eight hours.

This delay serves an important purpose. Even if signers approve a proposal, the community still needs time to review it. If someone notices a mistake or a malicious action hidden inside the proposal, the delay gives people time to react.

The queue stage acts like a cooling-off period. Nothing happens instantly.

During this time the proposal sits inside the timelock contract waiting for the timer to expire.

### Execution

After the waiting period ends, the proposal becomes executable.

At this point the protocol is finally allowed to perform the action defined in the proposal.

The timelock contract triggers the execution by sending the encoded transaction to the treasury contract. The treasury contract is responsible for performing the actual external call.

This design keeps responsibilities separate.

The timelock controls timing and permissions. The treasury holds funds and performs transactions.

When execution begins, the system performs one last set of checks. It confirms that the proposal still exists, verifies that it has not already been executed, and ensures the timelock delay has fully passed.

Once those checks succeed, the contract sends the call to the target address.

If the transaction completes successfully, the proposal status changes to executed. That status update prevents the proposal from running again.

So every proposal executes only once.

### Cancellation

Not every proposal should reach execution.

Sometimes new information appears after a proposal enters the queue. Maybe someone discovers a mistake in the transaction data. Maybe the community changes its mind. Or maybe the proposal becomes unnecessary.

For situations like this, the system includes a cancellation mechanism.

Authorized participants can cancel a proposal before execution happens. Once canceled, the proposal permanently stops moving forward.

The contract records the cancellation and the proposal cannot be executed later.

This feature acts like an emergency brake. If something suspicious appears during the timelock delay, the system still has a way to stop the action before it happens.

### Putting It All Together

When you look at the full process, the system behaves in a careful and predictable way.

First, someone creates a proposal describing an action.
Then governance signers review it and provide approvals.
Next the proposal enters a waiting period inside the timelock.
After the delay ends, the protocol executes the action through the treasury.
If a problem appears along the way, authorized users can cancel the proposal.

This step-by-step pipeline keeps governance decisions transparent and controlled. Every action passes through the same process, which makes the system easier to understand and much harder to abuse.

Instead of trusting one person or one contract, the protocol spreads responsibility across several stages. Each stage verifies something important before allowing the next step to happen.
