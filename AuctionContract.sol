pragma solidity ^0.4.24;

contract Auction{
    address public owner;
    //IPFS: Inter platenary file system foe svaing large amount of data.
    // IPFS is cost eefective and scable off chain decentralized soln for saving data
    uint public startBlock;
    uint public endBlock;
    
    string public ipfsHash;
    
    enum State{Started, Running, Ended, Cancelled}
    State public actionState;
    
    uint public highestBidingBid;
    address public highestBider;
    
    uint bidIncrement;
    
    mapping(address=>uint) public bids;
    
    constructor() public {
        owner = msg.sender;
        actionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        
        ipfsHash ="";
        
        bidIncrement =10;
    }
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    function min(uint a , uint b) pure internal returns (uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function placeBid() payable public notOwner afterStart beforeEnd returns (bool){
        require(actionState == State.Running);
        //require(msg.value >= 0.001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        
        require( currentBid > highestBidingBid );
        
        bids[msg.sender] = currentBid;
        
        if(currentBid <= bids[highestBider]){
            highestBidingBid = min(currentBid+bidIncrement,bids[highestBider]);
        }else{
            highestBidingBid = min(currentBid,bids[highestBider] + bidIncrement);
            highestBider = msg.sender;
        }
    return true;
    }
    
    function cancelAuction() public onlyOwner{
        actionState = State.Cancelled;
    }
    
    function finalizeAuction() public {
        require(actionState == State.Cancelled || block.number > endBlock);
        
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address recipient;
        uint value;
        
        if(actionState == State.Cancelled){
            recipient = msg.sender;
            value = bids[msg.sender];
        }else{
            if(msg.sender == owner){
                recipient = owner;
                value =  highestBidingBid;
            }else{
              if (msg.sender == highestBider){
                recipient = highestBider;
                value = bids[highestBider] - highestBidingBid;
            }else{ // this is neither the owner nor the highest bidder
                recipient = msg.sender;
                value = bids[msg.sender];
            }
            }
        }
        
        recipient.transfer(value);
    }
}
