# StackVote - Decentralized Governance & Voting Contract

## Overview

StackVote is a decentralized governance and voting contract built on the Stacks blockchain. It enables community members to participate in proposals, vote with weighted power based on their STX deposits, and earn rewards for participation.

## Features

### Core Functionality

- **Deposit System**: Users deposit STX to gain voting power proportional to their stake
- **Proposal Creation**: Community members can create proposals with title and description
- **Weight-Based Voting**: Voting power is determined by the amount of STX deposited
- **Proposal Execution**: Automatic execution and status tracking after voting deadline
- **Reward System**: Voters earn 2% rewards based on their voting weight
- **Vote Tracking**: Immutable record of all votes with timestamps and weights

## Contract Functions

### Public Functions

#### `deposit (amount: uint) -> Response`
Allows users to deposit STX and accumulate voting power.
- **Parameters**: `amount` (uint) - Amount of STX to deposit
- **Returns**: Success message or error

#### `create-proposal (title: string, description: string, duration: uint) -> Response`
Creates a new governance proposal with voting deadline.
- **Parameters**:
  - `title` (string-ascii 128) - Proposal title
  - `description` (string-ascii 256) - Proposal description
  - `duration` (uint) - Voting duration in blocks
- **Returns**: Proposal ID and creator address

#### `vote (proposal-id: uint, support: bool) -> Response`
Cast a vote on an active proposal.
- **Parameters**:
  - `proposal-id` (uint) - ID of the proposal to vote on
  - `support` (bool) - True for approval, false for rejection
- **Returns**: Confirmation message or error

#### `execute-proposal (proposal-id: uint) -> Response`
Executes a proposal after voting deadline and determines outcome.
- **Parameters**: `proposal-id` (uint) - ID of proposal to execute
- **Returns**: Proposal status (APPROVED/REJECTED)

#### `claim-reward (proposal-id: uint) -> Response`
Claims voting rewards for participation.
- **Parameters**: `proposal-id` (uint) - ID of voted proposal
- **Returns**: Reward amount or error

### Read-Only Functions

#### `get-proposal (id: uint) -> Proposal`
Retrieves proposal details including votes, description, and deadline.

#### `get-vote (proposal-id: uint, voter: principal) -> Vote`
Retrieves specific vote information including weight and support.

#### `get-total-proposals () -> uint`
Returns total number of proposals created.

#### `get-weight-of (voter: principal) -> uint`
Returns current voting power of a user.

## Data Structures

### Proposal
```
{
  creator: principal,
  title: string-ascii (128),
  description: string-ascii (256),
  for-votes: uint,
  against-votes: uint,
  total-staked: uint,
  deadline: uint (block height),
  executed: bool
}
```

### Vote
```
{
  support: bool,
  weight: uint (STX amount),
  timestamp: uint (block height),
  rewarded: bool
}
```

### Deposit
```
{
  voter: principal,
  amount: uint (total STX locked)
}
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR_NOT_ADMIN | Caller is not contract admin |
| 101 | ERR_NOT_FOUND | Proposal or vote not found |
| 102 | ERR_ALREADY_VOTED | Voter has already voted on proposal |
| 103 | ERR_VOTING_CLOSED | Voting deadline has passed |
| 104 | ERR_NO_FUNDS | Voter has insufficient deposit/weight |
| 105 | ERR_INVALID_AMOUNT | Invalid amount or empty input |

## How It Works

1. **User deposits STX** → Gains voting power equal to deposit amount
2. **Creator proposes** → Sets title, description, and voting duration
3. **Users vote** → Cast weighted votes based on deposit amount
4. **Deadline passes** → Proposal automatically executed
5. **Voter claims reward** → Receives 2% of voting weight as incentive

## Parameters

- **Voter Reward Rate**: 2% of voting weight
- **Max Title Length**: 128 ASCII characters
- **Max Description Length**: 256 ASCII characters
- **Duration**: Configurable in blocks

## Security Considerations

- One vote per user per proposal
- Voting power locked during active proposals
- Rewards can only be claimed once per vote
- Immutable vote records with timestamps
- Owner-controlled access for admin functions

## File Location

```
c:\Users\USER\Desktop\STACKS\USED\stackvote\contracts\stackvote.clar
```

---

For additional information or contributions, refer to the project structure in the stackvote directory.
