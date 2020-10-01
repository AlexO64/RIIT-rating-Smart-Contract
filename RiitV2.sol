pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract Admin {
    mapping(address => bool) public admins;

    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
        _;
    }
    
    function addAdmin( address newAdmin) onlyAdmin public {
        admins[newAdmin] = true;
    }
    
    function removeAdmin( address oldAdmin) onlyAdmin public {
        admins[oldAdmin] = false;
    }
}

contract RiitRating is Admin {
    /*
    Begin Specification part of contracts - responsible for Specification for RiitRating
    */
    
    struct Spec {
        int id; // id of Decription
        string name; // name ofr Description
        bool isPositive;  // if true, that then it is positive attribute
        int power;   // voting power of Decriptions
    }
    
    uint256 public maxSpecNumber = 16;
    Spec[] public specification;
    mapping(int => uint256) public specIdToStorageIndex;
    
    function updateMaxSpecNumber( uint newMaxNumber) onlyAdmin public{
        require( newMaxNumber > specification.length );
        maxSpecNumber = newMaxNumber;
    }
    
    function addSpec(int id, string memory name, bool isPositive, int power ) onlyAdmin public {
        require(specification.length < maxSpecNumber );
        specification.push(Spec({id: id, name: name, isPositive: isPositive, power: power}));
        specIdToStorageIndex[id] = specification.length - 1;
    }
   

    function updatePowerById(int id, int newPower) onlyAdmin public {
        require(specification.length > specIdToStorageIndex[id] || specification[ 0 ].id == id );
        specification[specIdToStorageIndex[id]].power = newPower;
    }
   
    function getAllSpecs() public view returns(int[] memory, string[] memory){
        int[] memory ids = new int[](specification.length) ;
        string[] memory names = new string[](specification.length) ;

        for (uint i = 0; i < specification.length; i++) {
            ids[i] = specification[i].id;
            names[i] = specification[i].name;
        }
        return (ids, names);
    }
    
    /*
    End Specification part of contracts - responsible for Specification for RiitRating
    */
    
    /*
    Begin Agent part of contracts - responsible for Agent adding for RiitRating
    */
    
    struct AverageSpecMark{
        uint16 numEvents;
        int16 average;
    }
    
    struct Agent{
        int id; // id of Agent
        string name; // name ofr Agent
        address adr; // Eth address of agent
        bool isCustomer;  // true if agent can be Customer
        bool isExecutor;  // true if agent can be isExecutor
        mapping(int => AverageSpecMark) marks;
    }
    
    Agent[] public agents;
    mapping(int => uint256) public agentIdToStorageIndex;
    
    function addAgent(int id, string memory name, address agentAddress, bool isCustomer, bool isExecutor ) onlyAdmin public {
        agents.push(Agent({id: id, name: name, adr: agentAddress, isCustomer: isCustomer, isExecutor: isExecutor }));
        agentIdToStorageIndex[id] = agents.length - 1;
    }
    
    /*
    End Agent part of contracts - responsible for Agent adding for RiitRating
    */
    
    
    /*
    Begin Order part of contracts - responsible for Orders RiitRating
    */
    
    struct Order{
        int id; // id of Orders
        string info;
        int custormerId; // id of custormer
        int executorId; // id of executor
        bool isCustomerConfirmed;
        uint customerConfirmationDate;
        bool isExecutorConfirmed;
        uint executorConfirmationDate;
    }
    
    Order[] public orders;
    mapping(int => uint256) public orderIdToStorageIndex;
    mapping(int => int[]) public agentOrders;
    mapping(int => int[]) public agentUnconfirmedOrders;
    
    function addOrdert(int id, string info, int custormerId, int executorId, bool isCustomerConfirmed, bool isExecutorConfirmed ) public {
        require(agents[agentIdToStorageIndex[custormerId]].isCustomer == true, "Agent not exists or not Customer.");
        require(agents[agentIdToStorageIndex[executorId]].isExecutor == true, "Agent not exists or not Executor.");
        require(custormerId != executorId, "Customer not allowed to be Executor of the same order.");
        
        uint customerDate = isCustomerConfirmed == true? now : 0;
        uint executorDate = isExecutorConfirmed == true? now : 0;
        
        orders.push(Order({id: id, info: info, custormerId: custormerId, executorId: executorId, isCustomerConfirmed: isCustomerConfirmed, customerConfirmationDate: customerDate, isExecutorConfirmed: isExecutorConfirmed, executorConfirmationDate: executorDate }));
        orderIdToStorageIndex[id] = orders.length - 1;
        
        agentOrders[custormerId].push(id);
        
        agentOrders[executorId].push(id);
        
        if( isCustomerConfirmed == false || isExecutorConfirmed == false){
            agentUnconfirmedOrders[custormerId].push(id);
            agentUnconfirmedOrders[executorId].push(id);
        }
    }
    
    function changeOrderStatus( Order memory order ) public {
        for( uint i = 0; i < agentUnconfirmedOrders[order.custormerId].length; i++){
            if( agentUnconfirmedOrders[order.custormerId][i] == order.id){
                if( agentUnconfirmedOrders[order.custormerId].length > 1 ){
                     agentUnconfirmedOrders[order.custormerId][i] = agentUnconfirmedOrders[order.custormerId][agentUnconfirmedOrders[order.custormerId].length - 1];
                }
                agentUnconfirmedOrders[order.custormerId][agentUnconfirmedOrders[order.custormerId].length - 1] = 0;
                agentUnconfirmedOrders[order.custormerId].length--;
                break;
            }
        }
        
        for( i = 0; i < agentUnconfirmedOrders[order.executorId].length; i++){
            if( agentUnconfirmedOrders[order.executorId][i] == order.id){
                if( agentUnconfirmedOrders[order.executorId].length > 1 ){
                     agentUnconfirmedOrders[order.executorId][i] = agentUnconfirmedOrders[order.executorId][agentUnconfirmedOrders[order.executorId].length - 1];
                }
                agentUnconfirmedOrders[order.executorId][agentUnconfirmedOrders[order.executorId].length - 1] = 0;
                agentUnconfirmedOrders[order.executorId].length--;
                break;
            }
        }
        
    }
    
    function ConfirmOrderByCustomer( int id ) public {
        Order storage order = orders[orderIdToStorageIndex[id]];
        if( order.isCustomerConfirmed == true ) {
            revert("Order already confirmed by customer.");
        }
        if( msg.sender != agents[agentIdToStorageIndex[order.custormerId]].adr){
            revert("Only customer can confirm.");
        }
        order.isCustomerConfirmed = true;
        order.customerConfirmationDate = now;
        
        if(order.isExecutorConfirmed == true){
            changeOrderStatus(order);
        }
    }
    
    function ConfirmOrderByExecutor( int id ) public {
        Order storage order = orders[orderIdToStorageIndex[id]];
        if( order.isExecutorConfirmed == true ) {
            revert("Order already confirmed by executor.");
        }
        if( msg.sender != agents[agentIdToStorageIndex[order.executorId]].adr){
            revert("Only executor can confirm.");
        }
        order.isExecutorConfirmed = true;
        order.executorConfirmationDate = now;
        
         if(order.isCustomerConfirmed == true){
            changeOrderStatus(order);
        }
    }
    
    function getUnconfirmedOrders(int agentId) public view returns(int[] memory, string[] memory){
        require( msg.sender == agents[agentIdToStorageIndex[agentId]].adr, "Identity of user is not confirmed." );
        
        int[] memory ids = new int[](agentUnconfirmedOrders[agentId].length) ;
        string[] memory infos = new string[](agentUnconfirmedOrders[agentId].length) ;

        for (uint i = 0; i < agentUnconfirmedOrders[agentId].length; i++) {
            ids[i] = orders[orderIdToStorageIndex[agentUnconfirmedOrders[agentId][i]]].id;
            infos[i] = orders[orderIdToStorageIndex[agentUnconfirmedOrders[agentId][i]]].info;
        }
        return (ids, infos);
    }
    
    /*
    End Order part of contracts - responsible for Orders RiitRating
    */
}
