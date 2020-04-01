pragma solidity ^0.4.24;
contract ERC20Interface{
    function totalSupply() public view returns (uint);
    function balanceOf( address tokenOwner) public view returns (uint balance);
    function transfer ( address to, uint tokens) public returns (bool success);
    
    function allowance(address tokenOwner , address spender) public view returns (uint remaining);
    function approve( address spender, uint tokens) public returns (bool success);
    function transferFrom( address from, address to, uint tokens) public returns (bool success);
    
    event Transfer( address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint token);
}
// When you deploy the contract on the block chain space, this contract will get assigned a address.
// When someone wants to transfer or send tokens to the contract address they will require the assigned 
// address;
// These token should not be send to the assigned address, else you might lose these token.

contract Cryptos is ERC20Interface{
    string public name = 'Cryptos';
    string public sysmbol = 'CRPT';
    // No of decimals places
    uint public decimals = 0;
    // Total no of tokens
    uint public supply;
    // The person deploying this contract
    address public founder;
    // Keep a key value pair of address and the money
    mapping(address => uint) public balances;
    // For naming sake and mandatory, you need to have the event name start with Capitalize 
    event Transfer( address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint token);
    
    mapping(address => mapping(address => uint)) allowed;
    //allowed[0x1111...][0x2222..] = tokens;
    //allowed[address_of_A][address_of_B] = 100;
    constructor() public{
        supply = 3000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    function balanceOf( address tokenOwner) public view returns (uint){
        return balances[tokenOwner];
    }
    function transfer ( address to, uint tokens) public returns (bool){
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    // Returns the remaing amount from which spender can see how much he still allowed to ask.
    function allowance(address tokenOwner , address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];
    }
    
    function approve( address spender, uint tokens) public returns (bool){
        require(balances[msg.sender] >= tokens && tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom( address from, address to, uint tokens) public returns (bool){
        // allowed 100 asking 20 tokens.
        require(allowed[from][to] >= tokens && balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        
        return true;
        
    }
}

// There are more approaches to have ICO but a good approach is to derive the ICO contract
// from the ERC contract.

contract CryptosICO is Cryptos{
    address public admin;
    address public deposit;
    
    //token price in wei: 1CRPT = 0.001 Ether, 1 Ether = 1000 CRPT
    
    uint tokenPrice = 1000000000000000000;
    
    //300 Ether in wei;
    uint public hardCap = 300000000000000000000;
    
    uint public raisedAmount;
    
    uint public saleStart = now;
    
    uint public saleEnd = now + 604800; // one week in secons 
    // 60 * 60 * 24 * 7 = 60 sec X 60 min X 24 hours X 7 days in one week.
    
    uint public coinTradeStart = saleEnd + 604800; // After one week we will transfer the  tokens;
    
    uint public maxInvestment = 5000000000000000000;
    
    uint public minInvestment = 100000000000000000;
    
    enum State { beforeStart, running, afterEnd, halted }
    State public icoState;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint token);
    
    constructor(address _deposit) public {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    // Emergency stop 
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    // beforeStart
    function unhalt() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp  < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
        //invest only when running
        icoState = getCurrentState();
        require(icoState == State.running);
        
        require(msg.value >= minInvestment && msg.value >= maxInvestment);
        
        uint tokens = msg.value / tokenPrice;
        
        //hard cap not reached;
        
        require(raisedAmount + msg.value <= hardCap);
        raisedAmount += msg.value;
        // Right now this shows that msg.sender will receive cryptos in exchange of Ether
        balances[msg.sender] += tokens;
        // This will reduce the token from founders acount.
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value); //transfer ETH to the deposit address.
        
        emit Invest(msg.sender,msg.value,tokens);
        
        return true;
    }
    
    function () payable public{
        invest();
    }
    
    modifier timeGreaterThanEnd {
        require(block.timestamp > coinTradeStart);
        _;
    }
    // over rides the transfer function in base contract
    function transfer(address to, uint value) public  timeGreaterThanEnd returns(bool){
        super.transfer(to,value);
    }
    
    function transferFrom( address from, address to, uint tokens) public  timeGreaterThanEnd returns (bool){
        super.transferFrom(from,to,tokens);
    }
    
    //Good practice to burn token if not sold.
    
    // Burning = bargaing, and many other words
    
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}
