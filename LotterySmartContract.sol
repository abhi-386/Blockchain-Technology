pragma solidity ^0.4.24;

contract Lottery{
    address[] public players; //this is dynamic array with players address
    address public manager; // contarct manager
    
    constructor() public {
        manager = msg.sender;
    }
    // this is a fall back payable function will be automatically called when someone sends 
    // ether to our contract 
    function() payable public{
        require (msg.value > 0.01 ether);
            //if the expression evaluates to false then the transaction changes are reverted.
        players.push(msg.sender); // add address of the account that sends ether to tht players array.
    }
    
    function get_balance() view public returns(uint){
        require(msg.sender == manager);
        return address(this).balance; // return contract balance
    }
    /*
    This function can not be used in decentralized lottery that has access to large 
    amount of ether becuase these values from here are not 100 percent random.
    */
    // we will use this function and mod the return value from the player.length
    function random() public view returns(uint256){
        return uint256(keccak256(block.difficulty, block.timestamp, players.length));
    }
    
    function selectWinner() public {
        require(msg.sender == manager);
        uint r = random();
        uint index = r % players.length;
        address winner =  players[index];
        //transfer contract balance to the winner address
        winner.transfer(address(this).balance);
        
        players = new address[](0);//resetting the players dynamic array
    }
    
    function get_length() view public returns(uint){
        return players.length;
    }
}
