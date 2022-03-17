// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting {

  uint winningProposalId;
  WorkflowStatus public workfowState = WorkflowStatus.RegisteringVoters;
  mapping (address => Proposal) public votersWhiteList;

  struct Voter {
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
    uint winningProposalId;
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

  event VoterRegistered(address voterAddress); 
  event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
  event ProposalRegistered(uint proposalId);
  event Voted (address voter, uint proposalId);


  // worflow status manageable by Owner only
  function turnStateToRegisteringVoters() public onlyOwner { workfowState = WorkflowStatus.RegisteringVoters; }
  function turnStateToProposalsRegistrationStarted() public onlyOwner { workfowState = WorkflowStatus.ProposalsRegistrationStarted; }
  function turnStateToProposalsRegistrationEnded() public onlyOwner { workfowState = WorkflowStatus.ProposalsRegistrationEnded; }
  function turnStateToVotingSessionStarted() public onlyOwner { workfowState = WorkflowStatus.VotingSessionStarted; }
  function turnStateToVotingSessionEnded() public onlyOwner { workfowState = WorkflowStatus.VotingSessionEnded; }
  function turnStateToVotesTallied() public onlyOwner { workfowState = WorkflowStatus.VotesTallied; }

  // The owner can register voter 
  function registringVoter(address _address) public onlyOwner {
    require(workfowState == RegisteringVoters, "voter register is closed");
    votersWhiteList[_address] = Voter();
    emit VoterRegistered(_address);
  } 
} 

