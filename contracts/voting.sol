// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable{

  WorkflowStatus workflowState;
  mapping (address => Voter) votersWhiteList;
  Proposal[] proposals; 
  uint public winningProposalId;
 
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
    workflowState = WorkflowStatus.RegisteringVoters;
  }

  modifier isWhiteListed(address _address) {
    require(votersWhiteList[_address].isRegistered == true, "Not allowed");
    _;
  } 

  // worflow status manageable by Owner only
  function goToNextState() public onlyOwner {
    WorkflowStatus currentState = workflowState;

    if (currentState  == WorkflowStatus.RegisteringVoters) {
      workflowState = WorkflowStatus.ProposalsRegistrationStarted;
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationStarted) {
      workflowState = WorkflowStatus.ProposalsRegistrationEnded;
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationEnded) {
      workflowState = WorkflowStatus.VotingSessionStarted;
    } else if (currentState  == WorkflowStatus.VotingSessionStarted) {
      workflowState = WorkflowStatus.VotingSessionEnded;
    } else if (currentState  == WorkflowStatus.VotingSessionEnded) {
      workflowState = WorkflowStatus.VotesTallied;
    } 
  }



 
  function turnStateToVotesTallied() public onlyOwner { workflowState = WorkflowStatus.VotesTallied; }

   
  //The owner can register voter 
  function registringVoter(address _address) public onlyOwner {
    require(workflowState == WorkflowStatus.RegisteringVoters, "voter register is closed");
    require(votersWhiteList[_address].isRegistered == false, "Already registered");
    votersWhiteList[_address] = Voter(true, false, 0);
    emit VoterRegistered(_address);
  } 

  // Registring voter poposal
  //@params the indexes of the array proposal are use as the proposal _id 
  function regsitringProposal(string memory _proposal) public isWhiteListed(msg.sender){
    require(workflowState == WorkflowStatus.ProposalsRegistrationStarted, "proposal register is closed");
    proposals.push(Proposal(_proposal, 0));
    emit ProposalRegistered(proposals.length - 1);
  }

  // Get proposal with proposals array index 
  //@params _id is the index of the array proposal 
  function getProposal(uint _id) public view isWhiteListed(msg.sender) returns(string memory){
    if (proposals.length == 0) {
      return "No proposals yet";
    } else {
      return proposals[_id].description;
    }
  }

  function vote(uint _id) public isWhiteListed(msg.sender) {
    require(workflowState == WorkflowStatus.VotingSessionStarted, "Vote session is closed");
    require(votersWhiteList[msg.sender].hasVoted == false, "Already voted");
    proposals[_id].voteCount ++;
    votersWhiteList[msg.sender].hasVoted = true;
    votersWhiteList[msg.sender].votedProposalId = _id;
    emit Voted (msg.sender, _id);
  }

  // We looking for the largest voteCount and it index (as we use the index as proposal Id)
  function voteTally() public onlyOwner {
    require(workflowState == WorkflowStatus.VotingSessionEnded, "Vote session must be closed");
    uint256 largestCount;
    uint256 i;
    Proposal[] memory tempProposals = proposals; 

    for(i = 0; i < tempProposals.length; i++){
        if(tempProposals[i].voteCount > largestCount) {
            largestCount = tempProposals[i].voteCount; 
        } 
    }
     winningProposalId = i;   
  }

} 

