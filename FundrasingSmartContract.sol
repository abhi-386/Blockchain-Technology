pragma solidity ^0.4.24;

contract FundRasing{
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline; //this is a timestamp;
    uint public goal;
    uint public raisedAmount = 0;
    
    struct Request{
        string description;
        address recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    // Made an array of struct Request to store various requests.
    Request[] public requests;
    // These event / log will save all the value being received and sends.
    event ContributeEvent(address sender, uint value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event makePAymentEvent(address recipient , uint value);
    
    modifier onlyOwner(){
        require(msg.sender == admin);
        _;
    }
    constructor(uint _goal, uint _deadline )public{
        goal = _goal;
        deadline = now + _deadline;
        
        admin = msg.sender;
        minimumContribution = 10;
    }
    function createRequest(string _description, address _recipient, uint _value) public onlyOwner{
        // It will store in the memory rather than being in storage.
        Request memory new_request = Request({
            description: _description,
            recipient: _recipient,
            value: _value,
            completed: false,
            noOfVoters: 0
        });
        requests.push(new_request);
        
        emit CreateRequestEvent(_description,_recipient,_value);
    } 
    
    function voteRequest(uint index) public{
        // We work directly on an element of the array saved in storage. This is not a copy.
        Request storage thisRequest = requests[index];
        require(contributors[msg.sender] > 0);
        require(thisRequest.voters[msg.sender] == false);
        
        thisRequest.voters[msg.sender] == true; // This mark that the voter has voted;
        thisRequest.noOfVoters++;
    }
    
    function makepayment(uint index) public onlyOwner{
        Request storage thisRequest = requests[index];
        require(thisRequest.completed == false); // Transaction is still left to be Made
        
        require(thisRequest.noOfVoters > noOfContributors / 2); //more than 50% voted
        
        thisRequest.recipient.transfer(thisRequest.value); // transfer money to the recipient
        thisRequest.completed == true;
        
        emit makePAymentEvent(thisRequest.recipient,thisRequest.value);
    }
    function contribute() public payable{
        require(now < deadline);
        require(msg.value >= minimumContribution);
        // If the person has not initial contributed
        if(contributors[msg.sender] == 0){
            noOfContributors ++;
        }
        
        contributors[msg.sender] += msg.value;
         
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender,msg.value);
    }
    
    function get_balance() view public returns(uint){
        return address(this).balance;
    }
    // This will refund the money under few circumstances
    // a) Deadline is met
    // b) goal is not met
    function getRefund() public{
        require(now > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address recipient = msg.sender;
        uint value = contributors[recipient];
        
        recipient.transfer(value);
        contributors[recipient] = 0;
    }
}
