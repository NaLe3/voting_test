// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable{

  WorkflowStatus workflowState = WorkflowStatus.RegisteringVoters;
  mapping (address => Voter) votersWhiteList;
  mapping (uint => address) proposalOwners;
  Proposal[] public proposals; 
 
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

  event VoterRegistered(address voterAddress); 
  event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
  event ProposalRegistered(uint proposalId);
  event Voted (address voter, uint proposalId);

  // Adding the Owner as a potential voter
  constructor() {
    votersWhiteList[msg.sender] = Voter(true, false, 0);
  }

  modifier isWhiteListed(address _address) {
    require(votersWhiteList[_address].isRegistered == true, "Not allowed");
    _;
  } 

  // worflow status manageable by Owner only
  function turnStateToRegisteringVoters() public onlyOwner { workflowState = WorkflowStatus.RegisteringVoters; }
  function turnStateToProposalsRegistrationStarted() public onlyOwner { workflowState = WorkflowStatus.ProposalsRegistrationStarted; }
  function turnStateToProposalsRegistrationEnded() public onlyOwner { workflowState = WorkflowStatus.ProposalsRegistrationEnded; }
  function turnStateToVotingSessionStarted() public onlyOwner { workflowState = WorkflowStatus.VotingSessionStarted; }
  function turnStateToVotingSessionEnded() public onlyOwner { workflowState = WorkflowStatus.VotingSessionEnded; }
  function turnStateToVotesTallied() public onlyOwner { workflowState = WorkflowStatus.VotesTallied; }

   
  //The owner can register voter 
  function registringVoter(address _address) public onlyOwner {
    require(workflowState == WorkflowStatus.RegisteringVoters, "voter register is closed");
    require(votersWhiteList[_address].isRegistered == false, "Already registered");
    votersWhiteList[_address] = Voter(true, false, 0);
    emit VoterRegistered(_address);
  } 

  // Registring voter poposal
  function regsitringProposal(string memory _proposal) public isWhiteListed(msg.sender){
    require(workflowState == WorkflowStatus.ProposalsRegistrationStarted, "proposal register is closed");
    uint proposalId = proposals.length - 1;
    proposals.push(Proposal(_proposal, 0));
    proposalOwners[proposalId] = msg.sender;
    emit ProposalRegistered(proposalId);
  }

  // Get proposal with proposals array index
  function getProposal(uint _id) public view isWhiteListed(msg.sender) returns(string memory){
    if (proposals.length == 0) {
      return "No proposals yet";
    } else {
      return proposals[_id].description;
    }
  }

  function vote(uint _id) public isWhiteListed(msg.sender) {
    require(workflowState == WorkflowStatus.VotingSessionStarted, "Vote session is closed");
    require(votersWhiteList[msg.sender].hasVoted == true, "Already voted");
    proposals[_id].voteCount ++;
    votersWhiteList[msg.sender].hasVoted = true;
    votersWhiteList[msg.sender].votedProposalId = _id;
    emit Voted (msg.sender, _id);
  }

} 

