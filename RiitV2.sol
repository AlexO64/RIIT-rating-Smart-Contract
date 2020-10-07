pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract Admin {
    mapping(address => bool) public admins;

    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Only Admin should run this operation.");
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
    uint constant private maxSpecNumber = 8;
    uint constant private maxAvailableMark = 100;
    uint specLength;
   
    constructor( ) public {
        specLength = 0;
    }
   
    /*
    Begin Specification part of contracts - responsible for Specification for RiitRating
    */
   
    struct Spec {
        int id; // id of Decription
        string name; // name ofr Description
        int power;   // voting power of Decriptions
    }
   
    Spec[maxSpecNumber] public specification;
    mapping(int => uint256) public specIdToStorageIndex;
   
    event AddNewSpec(address creator, int id, string name, int power);
   
    function addSpec(int id, string memory name,  int power ) onlyAdmin public {
        require(specification.length < maxSpecNumber );
        specification[specLength] = Spec({id: id, name: name, power: power});
        specIdToStorageIndex[id] = specLength;
        specLength++;
        emit AddNewSpec( msg.sender, id, name, power);
    }
   

    function updatePowerById(int id, int newPower) onlyAdmin public {
        require(specIdToStorageIndex[id] < specLength || specification[ 0 ].id == id );
        specification[specIdToStorageIndex[id]].power = newPower;
    }
   
    function getAllSpecs() public view returns(int[] memory, string[] memory){
        int[] memory ids = new int[](specLength) ;
        string[] memory names = new string[](specLength) ;

        for (uint i = 0; i < specLength; i++) {
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
   
    struct SpecMark{
        uint16 numEvents;
        int16 average;
    }
   
    struct Agent{
        int id; // id of Agent
        string name; // name ofr Agent
        address adr; // Eth address of agent
        bool isCustomer;  // true if agent can be Customer
        bool isExecutor;  // true if agent can be isExecutor
    }
   
    Agent[] public agents;
    mapping(int => uint256) public agentIdToStorageIndex;
   
    event AddNewAgent(address creator, int id, string name, address agentAddress, bool isCustomer, bool isExecutor);
   
    function addAgent(int id, string memory name, address agentAddress, bool isCustomer, bool isExecutor ) onlyAdmin public {
        agents.push(Agent({id: id, name: name, adr: agentAddress, isCustomer: isCustomer, isExecutor: isExecutor  }));
        agentIdToStorageIndex[id] = agents.length - 1;
       
        emit AddNewAgent( msg.sender, id, name, agentAddress, isCustomer, isExecutor );
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
        int customerId; // id of custormer
        int executorId; // id of executor
        uint customerConfirmationDate;
        uint executorConfirmationDate;
    }
   
    Order[] public orders;
    mapping(int => uint256) public orderIdToStorageIndex;
    mapping(int => int[]) public agentOrders;
    mapping(int => int[]) public agentUnconfirmedOrders;
   
    event AddNewOrder(address creator, int id, string info, int customerId, int executorId);
   
    function addOrder(int id, string memory info, int customerId, int executorId, bool isCustomerConfirmed, bool isExecutorConfirmed ) public {
        require(agents[agentIdToStorageIndex[customerId]].isCustomer == true, "Agent not exists or not Customer.");
        require(agents[agentIdToStorageIndex[executorId]].isExecutor == true, "Agent not exists or not Executor.");
        require(customerId != executorId, "Customer not allowed to be Executor of the same order.");
       
        uint customerDate = isCustomerConfirmed == true? now : 0;
        uint executorDate = isExecutorConfirmed == true? now : 0;
       
        orders.push(Order({id: id, info: info, customerId: customerId, executorId: executorId, customerConfirmationDate: customerDate, executorConfirmationDate: executorDate }));
        orderIdToStorageIndex[id] = orders.length - 1;
       
        agentOrders[customerId].push(id);
       
        agentOrders[executorId].push(id);
       
        if( isCustomerConfirmed == false || isExecutorConfirmed == false){
            agentUnconfirmedOrders[customerId].push(id);
            agentUnconfirmedOrders[executorId].push(id);
        }
       
        emit AddNewOrder(msg.sender, id, info, customerId, executorId);
    }
   
    function changeOrderStatus( Order memory order ) private {
        for( uint i = 0; i < agentUnconfirmedOrders[order.customerId].length; i++){
            if( agentUnconfirmedOrders[order.customerId][i] == order.id){
                if( agentUnconfirmedOrders[order.customerId].length > 1 ){
                     agentUnconfirmedOrders[order.customerId][i] = agentUnconfirmedOrders[order.customerId][agentUnconfirmedOrders[order.customerId].length - 1];
                }
                agentUnconfirmedOrders[order.customerId].pop();
                break;
            }
        }
       
        for( uint i = 0; i < agentUnconfirmedOrders[order.executorId].length; i++){
            if( agentUnconfirmedOrders[order.executorId][i] == order.id){
                if( agentUnconfirmedOrders[order.executorId].length > 1 ){
                     agentUnconfirmedOrders[order.executorId][i] = agentUnconfirmedOrders[order.executorId][agentUnconfirmedOrders[order.executorId].length - 1];
                }
                agentUnconfirmedOrders[order.executorId].pop();
                break;
            }
        }
       
    }
   
    function ConfirmOrderByCustomer( int id ) public {
        Order storage order = orders[orderIdToStorageIndex[id]];
        if( order.customerConfirmationDate > 0 ) {
            revert("Order already confirmed by customer.");
        }
        if( msg.sender != agents[agentIdToStorageIndex[order.customerId]].adr){
            revert("Only customer can confirm.");
        }
        order.customerConfirmationDate = now;
       
        if(order.executorConfirmationDate > 0){
            changeOrderStatus(order);
        }
    }
   
    function ConfirmOrderByExecutor( int id ) public {
        Order storage order = orders[orderIdToStorageIndex[id]];
        if( order.executorConfirmationDate > 0 ) {
            revert("Order already confirmed by executor.");
        }
        if( msg.sender != agents[agentIdToStorageIndex[order.executorId]].adr){
            revert("Only executor can confirm.");
        }
        order.executorConfirmationDate = now;
       
         if(order.customerConfirmationDate > 0){
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
   
     /*
    Begin Review part of contracts - responsible for Review RiitRating
    */
   
    struct Review{
        int id; // id of Orders
        int orderId; // id of order
        address authorId; // author Id
        mapping(int => int) marks; // mark in pairs - first int - id spec, second - mark itself
        uint created;
    }
   
    Review[] public reviews;
    mapping(int => uint256) public reviewIdToStorageIndex;
    mapping(address => Review[]) public reviewByAuthor;
    mapping(address => Review[]) public userReviews;
   
    function addReview(int id, int orderId, int[] memory userMarks ) public {
        require(orders[orderIdToStorageIndex[orderId]].id == id, "Order not not exists.");
        require(userMarks.length < maxSpecNumber * 2 + 1, "Marks array length bigger then number od specs.");
        require(userMarks.length % 2 == 0, "Marks array length must be even.");
        Order memory order = orders[orderIdToStorageIndex[orderId]];
        require(
            agents[agentIdToStorageIndex[order.executorId]].adr == msg.sender
            ||
            agents[agentIdToStorageIndex[order.customerId]].adr == msg.sender,
            "You do not have access to this function. Must be customer or executors of this order."
        );
       
        address user;
        if(agents[agentIdToStorageIndex[order.executorId]].adr == msg.sender  ){
            user = agents[agentIdToStorageIndex[order.customerId]].adr;
        }else{
            user = agents[agentIdToStorageIndex[order.executorId]].adr;
        }
       
        reviews.push(Review({id: id, orderId: orderId, authorId: msg.sender, created: now}));
        reviewIdToStorageIndex[id] = reviews.length - 1;
       
        for( uint i = 0; i <= userMarks.length / 2; i++ ){
           reviews[reviews.length - 1].marks[(int)(i * 2)] = userMarks[(i * 2) + 1];
        }
       
        reviewByAuthor[msg.sender].push(reviews[reviews.length - 1]);
        userReviews[user].push(reviews[reviews.length - 1]);
    }
    /*
    End Review part of contracts - responsible for Review RiitRating
    */
   
}
	
	
	
