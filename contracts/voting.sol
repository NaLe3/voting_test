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

  // Automatically adding the contract owner as a potential voter
  constructor() {
    votersWhiteList[msg.sender] = Voter(true, false, 0);
    workflowState = WorkflowStatus.RegisteringVoters;
  }

  // Ensure the address is listed in the whitelist to participate in the voting
  modifier isWhiteListed(address _address) {
     require(votersWhiteList[_address].isRegistered == true, "Not regesitered");
    _;
  }

  /*
    Ensure the id proposal is correct
    For the Voter the proposal ID starts at "1" up to to the number of proposal (proposals.length)

  */
  modifier proposalIdAllowed(uint _id) {
    require(
      0 < _id && _id <= proposals.length,
      "This ID does not exist" 
    );
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
      CurrentStateToReturn = "Proposal registration is oponned"; 
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationStarted) {
      workflowState = currentState =   WorkflowStatus.ProposalsRegistrationEnded;
      previousState = WorkflowStatus.ProposalsRegistrationStarted;
      CurrentStateToReturn = "Proposal registration has ended"; 
    } else if (currentState  == WorkflowStatus.ProposalsRegistrationEnded) {
      workflowState = currentState =  WorkflowStatus.VotingSessionStarted;
      previousState = WorkflowStatus.ProposalsRegistrationEnded;
      CurrentStateToReturn = "Voting session is openned"; 
    } else if (currentState  == WorkflowStatus.VotingSessionStarted) {
      workflowState = currentState =  WorkflowStatus.VotingSessionEnded;
      previousState = WorkflowStatus.VotingSessionStarted;
      CurrentStateToReturn = "Voting session has ended, the Administrator needs to proceed to the vote tally"; 
    } 

    emit WorkflowStatusChange(previousState, currentState);
    return CurrentStateToReturn;
  }
   
  //The owner only can register new voter 
  function registringVoter(address _address) public onlyOwner {
    require(workflowState == WorkflowStatus.RegisteringVoters, "Voter register is closed");
    require(votersWhiteList[_address].isRegistered == false, "Already registered");
    votersWhiteList[_address] = Voter(true, false, 0);
    emit VoterRegistered(_address);
  } 

  /*
  Registring voter poposal
  @params the indexes of the array proposal are use as the proposal _id 
  */
  function regsitringProposal(string memory _proposal) public isWhiteListed(msg.sender){
    require(workflowState == WorkflowStatus.ProposalsRegistrationStarted, "Proposal register is closed");
    proposals.push(Proposal(_proposal, 0));
    emit ProposalRegistered(proposals.length);
  }

  /* 
  @params _id is the proposal ID. It starts at "1" for the voter,
  so we need to do proposals[_id - 1] to retreive the corresponding index
  */
  function getProposal(uint _id) public view isWhiteListed(msg.sender) proposalIdAllowed(_id) returns(string memory){
    require(proposals.length != 0, "No proposals yet");
    return proposals[_id - 1].description;
  }

  /*
  @params _id is the proposal ID. It starts at "1" for the voter, 
  so we need to do proposals[_id - 1] to retreive the corresponding index
  */
  function vote(uint _id) public isWhiteListed(msg.sender) proposalIdAllowed(_id) {
    require(workflowState == WorkflowStatus.VotingSessionStarted, "Vote session is closed");
    require(votersWhiteList[msg.sender].hasVoted == false, "Already voted");
    proposals[_id - 1].voteCount ++;
    votersWhiteList[msg.sender].hasVoted = true;
    votersWhiteList[msg.sender].votedProposalId = _id;
    emit Voted (msg.sender, _id);
  }

  function getVote(address _address) public view isWhiteListed(msg.sender) returns(string memory){
    require(votersWhiteList[_address].isRegistered == true, "Not regesitered");
    uint proposalId = votersWhiteList[_address].votedProposalId - 1;
    return proposals[proposalId].description;
  }

  /* We look for the largest voteCount by iterating in each proposals elements, 
  anytime the value(uint voteCount) is higher than the largestCournt, we replace 
  the later by this value.  
  */
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

  // Retreive the winning proposal description 
  function getWinner() public view isWhiteListed(msg.sender) returns(string memory) {
    require(workflowState == WorkflowStatus.VotesTallied, "Result is not published yet");
    return proposals[winningProposalId].description;
  }

} 

