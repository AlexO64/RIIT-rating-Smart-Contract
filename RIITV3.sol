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
    uint constant private maxSpecNumber = 8; //Max Available number characteristics
    uint constant private maxAvailableMark = 100; //Max mark
    uint constant private yearLength = 31622400; //Lenght for year
    
    constructor( ) public {
        specArrayLength = 0;
        agentArrayLength = 0;
        orderArrayLength = 0;
        reviewArrayLength = 0;
    }
   
    /*
    Begin Specification part of contracts - responsible for Specification for RiitRating
    */
   
    struct Spec {
        uint id; // id of Decription
        string name; // name ofr Description
        uint power;   // voting power of Decriptions
    }
   
    Spec[maxSpecNumber] public specification;
    uint specArrayLength;
   
    event AddNewSpec(address creator, uint id, string name, uint power);
   
    function addSpec(string memory name,  uint power ) onlyAdmin public returns( uint id ){
        require(specArrayLength < maxSpecNumber );
        id = specArrayLength + 1;
        specification[specArrayLength] = Spec({id: id, name: name, power: power});
        specArrayLength++;
        emit AddNewSpec( msg.sender, id, name, power);
    }
   

    function updatePowerById(uint id, uint newPower) onlyAdmin public {
        require(id <= specArrayLength );
        specification[id - 1].power = newPower;
    }
   
    function getAllSpecs() public view returns(uint[] memory, string[] memory){
        uint[] memory ids = new uint[](specArrayLength);
        string[] memory names = new string[](specArrayLength);

        for (uint i = 0; i < specArrayLength; i++) {
            ids[i] = i + 1;
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
        uint16 average;
    }
   
    struct Agent{
        uint id; // id of Agent
        string name; // name ofr Agent
        address adr; // Eth address of agent
        bool isCustomer;  // true if agent can be Customer
        bool isExecutor;  // true if agent can be isExecutor
    }
   
    Agent[] public agents;
    uint agentArrayLength;
   
    event AddNewAgent(address creator, uint id, string name, address agentAddress, bool isCustomer, bool isExecutor);
   
    function addAgent(string memory name, address agentAddress, bool isCustomer, bool isExecutor ) onlyAdmin public returns(uint id){
        id = agentArrayLength + 1;
        agents.push(Agent({id: id, name: name, adr: agentAddress, isCustomer: isCustomer, isExecutor: isExecutor  }));
        agentArrayLength++;
       
        emit AddNewAgent( msg.sender, id, name, agentAddress, isCustomer, isExecutor );
    }
   
    /*
    End Agent part of contracts - responsible for Agent adding for RiitRating
    */
   
   
    /*
    Begin Order part of contracts - responsible for Orders RiitRating
    */
   
    struct Order{
        uint id; // id of Orders
        string info;
        uint customerId; // id of custormer
        uint executorId; // id of executor
        uint customerConfirmationDate;
        uint executorConfirmationDate;
    }
   
    Order[] public orders;
    uint orderArrayLength;
    mapping(uint => uint[]) public agentOrders;
    mapping(uint => uint[]) public agentUnconfirmedOrders;
   
    event AddNewOrder(address creator, uint id, string info, uint customerId, uint executorId);
   
    function addOrder(string memory info, uint customerId, uint executorId, bool isCustomerConfirmed, bool isExecutorConfirmed ) public returns(uint id){
        require( customerId > 0 && customerId <= agentArrayLength, "Customer with such id is not exists");
        require( executorId > 0 && executorId <= agentArrayLength, "Executeor with such d is not exists");
        require(agents[customerId - 1].isCustomer == true, "Agent not exists or not Customer.");
        require(agents[executorId -1].isExecutor == true, "Agent not exists or not Executor.");
        require(customerId != executorId, "Customer not allowed to be Executor of the same order.");
       
        uint customerDate = isCustomerConfirmed == true? now : 0;
        uint executorDate = isExecutorConfirmed == true? now : 0;
        id = orderArrayLength + 1;
        orders.push(Order({id: id, info: info, customerId: customerId, executorId: executorId, customerConfirmationDate: customerDate, executorConfirmationDate: executorDate }));
        orderArrayLength++;
       
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
   
    function ConfirmOrderByCustomer( uint id ) public {
        Order storage order = orders[id - 1];
        if( order.customerConfirmationDate > 0 ) {
            revert("Order already confirmed by customer.");
        }
        if( msg.sender != agents[order.customerId -1].adr){
            revert("Only customer can confirm.");
        }
        order.customerConfirmationDate = now;
       
        if(order.executorConfirmationDate > 0){
            changeOrderStatus(order);
        }
    }
   
    function ConfirmOrderByExecutor( uint id ) public {
        Order storage order = orders[id - 1];
        if( order.executorConfirmationDate > 0 ) {
            revert("Order already confirmed by executor.");
        }
        if( msg.sender != agents[order.executorId - 1].adr){
            revert("Only executor can confirm.");
        }
        order.executorConfirmationDate = now;
       
         if(order.customerConfirmationDate > 0){
            changeOrderStatus(order);
        }
    }
   
    function getUnconfirmedOrders(uint agentId) public view returns(uint[] memory, string[] memory){
        require( msg.sender == agents[agentId - 1].adr, "Identity of user is not confirmed." );
       
        uint[] memory ids = new uint[](agentUnconfirmedOrders[agentId].length) ;
        string[] memory infos = new string[](agentUnconfirmedOrders[agentId].length) ;

        for (uint i = 0; i < agentUnconfirmedOrders[agentId].length; i++) {
            ids[i] = orders[agentUnconfirmedOrders[agentId][i]].id;
            infos[i] = orders[agentUnconfirmedOrders[agentId][i]].info;
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
        uint id; // id of Orders
        uint orderId; // id of order
        address authorId; // author Id
        uint created;
    }
   
    Review[] public reviews;
    uint reviewArrayLength;
    
    mapping(uint => uint[]) reviewMarks;    // marks for review
    mapping(uint => uint[]) reviewByAuthor;   // reviews submitted by author
    mapping(uint => uint[]) userReviews;      // customer reviews 
    mapping(uint => uint) startCalculationReviewIndex;
    
    function addReview( uint orderId, uint[] memory userMarks ) public returns(uint id){
        require(orderId <= orderArrayLength, "Order not not exists.");
        require(userMarks.length <= specArrayLength, "Marks array length should be equal specs lenght.");
        
        Order memory order = orders[orderId - 1];
        require(
            agents[order.executorId - 1].adr == msg.sender
            ||
            agents[order.customerId - 1].adr == msg.sender,
            "You do not have access to this function. Must be customer or executors of this order."
        );
       
        uint author;
        uint user;
        
        if(agents[order.executorId - 1].adr == msg.sender  ){
            author = agents[order.customerId - 1].id;
            user = agents[order.executorId - 1].id;
        }else{
            author = agents[order.executorId - 1].id;
            user = agents[order.customerId - 1].id;
        }
        
        id = reviewArrayLength + 1;
        reviews.push(Review({id: id, orderId: orderId, authorId: msg.sender, created: now}));
        
        for( uint i = 0; i <= userMarks.length; i++ ){
           reviewMarks[reviewArrayLength].push(userMarks[i]);
        }
       
        reviewByAuthor[author].push(id);
        userReviews[user].push(id);
        reviewArrayLength++;
    }
    
    /*
    End Review part of contracts - responsible for Review RiitRating
    */
    
    /*
    Begin Function for get ranking of customerId
    */
    function getAverageScore( uint agentId ) public returns( uint ){
        uint startIndex = startCalculationReviewIndex[agentId];
        uint eventsCount = 0;
        uint[] memory summary = new uint[](specArrayLength);
        
        for( uint i = startIndex; i < userReviews[agentId].length; i++){
            uint idx = userReviews[agentId][i];
            if(reviews[idx].created  + yearLength < now){
                startIndex++;
            }else{
                for(uint iSpecs = 0; iSpecs < specArrayLength; iSpecs++){
                    if(reviewMarks[idx][iSpecs] <= maxAvailableMark){
                        summary[iSpecs] = summary[iSpecs] + reviewMarks[idx][iSpecs];
                    }else{
                        summary[iSpecs] = summary[iSpecs] + maxAvailableMark;
                    }
                }
                eventsCount++;
            }
        }
        
        startCalculationReviewIndex[agentId] = startIndex;
        
        if(eventsCount == 0){
            return maxAvailableMark;
        }
        
        uint rank = 0;
        uint weigth = 0;
        for( uint iSpecs = 0; iSpecs < specArrayLength; iSpecs++ ){
            rank = rank + summary[iSpecs] * specification[iSpecs].power / eventsCount;
            weigth = weigth + specification[iSpecs].power;
        }
        
        return rank / weigth;
    }   
    /*
    End Review part of contracts - responsible for Review RiitRating
    */
    
    
   
}
	
	
	
