// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable{

  WorkflowStatus workflowState;
  mapping (address => Voter) votersWhiteList;
  Proposal[] proposals; 
  uint winningProposalId;
 
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

  /*
    worflow status manageable by Owner only
    @dev the variable CurrentStateToReturn has been implemented to track 
    the current state for development purpose (debugging)
  */
  function goToNextState() public onlyOwner returns(string memory){
    WorkflowStatus currentState = workflowState;
    WorkflowStatus previousState;
    string memory CurrentStateToReturn; 

    if (currentState  == WorkflowStatus.RegisteringVoters) {
      workflowState = currentState = WorkflowStatus.ProposalsRegistrationStarted;
      previousState = WorkflowStatus.RegisteringVoters;
      CurrentStateToReturn = "State is ProposalsRegistrationStarted"; 
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationStarted) {
      workflowState = currentState =   WorkflowStatus.ProposalsRegistrationEnded;
      previousState = WorkflowStatus.ProposalsRegistrationStarted;
      CurrentStateToReturn = "State is ProposalsRegistrationEnded"; 
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationEnded) {
      workflowState = currentState =  WorkflowStatus.VotingSessionStarted;
      previousState = WorkflowStatus.ProposalsRegistrationEnded;
      CurrentStateToReturn = "State is VotingSessionStarted"; 
    } else if (currentState  == WorkflowStatus.VotingSessionStarted) {
      workflowState = currentState =  WorkflowStatus.VotingSessionEnded;
      previousState = WorkflowStatus.VotingSessionStarted;
      CurrentStateToReturn = "State is VotingSessionEnded, proceed to the vote tally"; 
    } 

    emit WorkflowStatusChange(previousState, currentState);
    return CurrentStateToReturn;
  }
   
  //The owner only can register voter 
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
    emit ProposalRegistered(proposals.length);
  }

  /* 
  Get proposal with proposals array index 
  @params _id start at "1" for the voter
  therefore as we use the proposals index for proposal id
  we need to do proposals[_id - 1] to return the proposal decription expected
  */
  function getProposal(uint _id) public view isWhiteListed(msg.sender) returns(string memory){
    if (proposals.length == 0) {
      return "No proposals yet";
    } else {
      return proposals[_id - 1].description;
    }
  }

  function vote(uint _id) public isWhiteListed(msg.sender) {
    require(workflowState == WorkflowStatus.VotingSessionStarted, "Vote session is closed");
    require(votersWhiteList[msg.sender].hasVoted == false, "Already voted");
    proposals[_id - 1].voteCount ++;
    votersWhiteList[msg.sender].hasVoted = true;
    votersWhiteList[msg.sender].votedProposalId = _id;
    emit Voted (msg.sender, _id);
  }

  // We look for the largest voteCount and it index (as we use the index as proposal Id)
  function voteTally() public onlyOwner {
    require(workflowState == WorkflowStatus.VotingSessionEnded, "Vote session must be closed");
    uint256 largestCount;
    uint256 largestVoteCountId;
    uint256 i;
    Proposal[] memory tempProposals = proposals; 

    for(i = 0; i < tempProposals.length; i++){
        if(tempProposals[i].voteCount > largestCount) {
            largestCount = tempProposals[i].voteCount; 
            largestVoteCountId = i;
        } 
    }

    workflowState = WorkflowStatus.VotesTallied;
     winningProposalId = largestVoteCountId;

    emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    
  }

  function getWinner() public view isWhiteListed(msg.sender) returns(string memory) {
    require(
      winningProposalId != 0 && workflowState == WorkflowStatus.VotesTallied, 
      "Result is not published yet"
    );
    return proposals[winningProposalId].description;
  }

} 

