// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VirtualDebateLeague {
    struct Debate {
        string topic;
        address creator;
        uint256 prizePool;
        address[] participants;
        mapping(address => string) arguments;
        mapping(address => uint256) votes;
        bool finalized;
    }

    mapping(uint256 => Debate) public debates;
    uint256 public debateCount;

    uint256 public constant PARTICIPATION_FEE = 0.01 ether;
    mapping(address => uint256) public tokenBalances;

    event DebateCreated(uint256 indexed debateId, string topic, address indexed creator);
    event ArgumentSubmitted(uint256 indexed debateId, address indexed participant, string argument);
    event Voted(uint256 indexed debateId, address indexed voter, address indexed participant);
    event DebateFinalized(uint256 indexed debateId, address winner);

    function createDebate(string memory _topic) external payable {
        require(msg.value >= PARTICIPATION_FEE, "A minimum fee is required to create a debate");

        Debate storage debate = debates[debateCount];
        debate.topic = _topic;
        debate.creator = msg.sender;
        debate.prizePool = msg.value;

        debateCount++;

        emit DebateCreated(debateCount - 1, _topic, msg.sender);
    }

    function joinDebate(uint256 _debateId, string memory _argument) external payable {
        Debate storage debate = debates[_debateId];
        require(!debate.finalized, "Debate has been finalized");
        require(msg.value >= PARTICIPATION_FEE, "Participation fee required");

        debate.participants.push(msg.sender);
        debate.arguments[msg.sender] = _argument;
        debate.prizePool += msg.value;

        emit ArgumentSubmitted(_debateId, msg.sender, _argument);
    }

    function vote(uint256 _debateId, address _participant) external {
        Debate storage debate = debates[_debateId];
        require(!debate.finalized, "Debate has been finalized");
        require(bytes(debate.arguments[_participant]).length > 0, "Participant must have submitted an argument");

        debate.votes[_participant] += 1;

        emit Voted(_debateId, msg.sender, _participant);
    }

    function finalizeDebate(uint256 _debateId) external {
        Debate storage debate = debates[_debateId];
        require(!debate.finalized, "Debate has already been finalized");
        require(debate.participants.length > 0, "No participants in the debate");

        address winner;
        uint256 highestVotes = 0;

        for (uint256 i = 0; i < debate.participants.length; i++) {
            address participant = debate.participants[i];
            if (debate.votes[participant] > highestVotes) {
                highestVotes = debate.votes[participant];
                winner = participant;
            }
        }

        require(winner != address(0), "No votes received");

        tokenBalances[winner] += debate.prizePool;
        debate.finalized = true;

        emit DebateFinalized(_debateId, winner);
    }

    function withdrawTokens() external {
        uint256 amount = tokenBalances[msg.sender];
        require(amount > 0, "No tokens to withdraw");

        tokenBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}

