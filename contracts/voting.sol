// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting {

  struct Voter {
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
  }

  struct Proposal {
    string description;
    uint voteCount;
  }

  enum WorkflowStatus {
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    VotesTallied
  }

} 