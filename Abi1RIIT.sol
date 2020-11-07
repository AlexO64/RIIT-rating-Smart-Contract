pragma solidity >=0.4.22 <0.7.0;

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

    uint constant private maxSpecNumber = 3; //Max Available number characteristics
    uint8 constant private minAvailableMark = 1; //Max mark
    uint8 constant private maxAvailableMark = 100; //Max mark

    constructor( ) public {
        specArrayLength = 0;
        agentArrayLength = 0;
        orderArrayLength = 0;
    }
    
    /*
    Common functions - do not belong any parts of contract
    */

    receive() external payable {
       if( msg.value != 0 ){
            revert( "Don't send ether to this contract." );
        }
    }
    
    fallback() external payable { 
        if( msg.value != 0 ){
            revert( "Don't send ether to this contract." );
        }
    }
   
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /*
    End Common functions - do not belong any parts of contract
    */

    
    /*
    Begin Specification part of contracts - responsible for Specification for RiitRating
    */

    struct Spec {
        uint id; // id of Decription
        string name; // name ofr Description
        uint16 power;   // voting power of Decriptions
    }

    Spec[maxSpecNumber] public specification;
    uint specArrayLength;

    event AddNewSpec(address creator, uint id, string name, uint16 power);

    function addSpec(string memory name,  uint16 power ) onlyAdmin public returns( uint ){
        require(specArrayLength < maxSpecNumber, "You already fill up all specs." );
        uint id = specArrayLength + 1;
        specification[specArrayLength] = Spec({id: id, name: name, power: power});
        specArrayLength++;
        emit AddNewSpec( msg.sender, id, name, power);
        
        return id;
    }

    function updatePowerById(uint id, uint16 newPower) onlyAdmin public {
        require(id <= specArrayLength );
        specification[id - 1].power = newPower;
    }

    function getAllSpecs() public view returns(uint[] memory, bytes32[] memory){
        uint[] memory ids = new uint[](specArrayLength);
        bytes32[] memory names = new bytes32[](specArrayLength);

        for (uint i = 0; i < specArrayLength; i++) {
            ids[i] = i + 1;
            names[i] = stringToBytes32(specification[i].name);
        }

        return (ids, names);
    }

  
    /*
    End Specification part of contracts - responsible for Specification for RiitRating
    */

    /*
    Begin Agent part of contracts - responsible for Agent adding for RiitRating
    */

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

    function addAgent(string memory name, address agentAddress, bool isCustomer, bool isExecutor ) onlyAdmin public returns(uint){
        uint id = agentArrayLength + 1;
        agents.push(Agent({id: id, name: name, adr: agentAddress, isCustomer: isCustomer, isExecutor: isExecutor  }));
        agentArrayLength++;

        emit AddNewAgent( msg.sender, id, name, agentAddress, isCustomer, isExecutor );
        return id;
    }

    /*
    End Agent part of contracts - responsible for Agent adding for RiitRating
    */

    /*
    Begin Order part of contracts - responsible for Orders RiitRating
    */

    enum OrderState { Created, Confirmed, Reviewed }

    struct Order{
        uint id; // id of Orders
        string info;
        uint customerId; // id of custormer
        uint executorId; // id of executor
        OrderState customerState;
        OrderState executorState;
    }


    Order[] public orders;
    uint orderArrayLength;

    mapping(uint => uint[]) public agentOrders;
    mapping(uint => uint[]) public agentUnconfirmedOrders;

    event AddNewOrder(address creator, uint id, string info, OrderState customerState, OrderState executorState);

    function addOrder(string memory info, uint customerId, uint executorId, OrderState customerState, OrderState executorState) public returns(uint){
        require( customerId > 0 && customerId <= agentArrayLength, "Customer with such id is not exists");
        require( executorId > 0 && executorId <= agentArrayLength, "Executeor with such d is not exists");
        require(agents[customerId - 1].isCustomer == true, "Agent not exists or not Customer.");
        require(agents[executorId -1].isExecutor == true, "Agent not exists or not Executor.");
        require(customerId != executorId, "Customer not allowed to be Executor of the same order.");
        require((customerState == OrderState.Created || customerState == OrderState.Confirmed)
            && (executorState == OrderState.Created || executorState == OrderState.Confirmed),
        "Incorrect State for one of participant.");
        
        uint id = orderArrayLength + 1;

        orders.push(Order({id: id, info: info, customerId: customerId, executorId: executorId, customerState: customerState, executorState: executorState }));
        //orders.push(Order({id: id, info: info, customerId: customerId, executorId: executorId, customerState: OrderState.Confirmed, executorState: OrderState.Confirmed }));
        orderArrayLength++;

        agentOrders[customerId].push(id);
        agentOrders[executorId].push(id);

        if( customerState != OrderState.Confirmed || executorState != OrderState.Confirmed){ 
            agentUnconfirmedOrders[customerId].push(id);
            agentUnconfirmedOrders[executorId].push(id);
        } 

        emit AddNewOrder(msg.sender, id, info, customerState, executorState);
        return id;
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
        if( order.customerState ==  OrderState.Confirmed || order.customerState == OrderState.Reviewed ) {
            revert("Order already confirmed by customer.");
        }

        if( msg.sender != agents[order.customerId -1].adr){
            revert("Only customer can confirm.");
        }

        order.customerState = OrderState.Confirmed;

        if(order.executorState == OrderState.Confirmed ){
            changeOrderStatus(order);
        }
    }

    function ConfirmOrderByExecutor( uint id ) public {
        Order storage order = orders[id - 1];
        if( order.executorState ==  OrderState.Confirmed || order.executorState == OrderState.Reviewed ) {
            revert("Order already confirmed by executor.");
        }

        if( msg.sender != agents[order.executorId - 1].adr){
            revert("Only executor can confirm.");
        }

        order.executorState = OrderState.Confirmed;

         if(order.customerState == OrderState.Confirmed){
            changeOrderStatus(order);
        }
    }

    function getUnconfirmedOrders(uint agentId) public view returns(uint[] memory, bytes32[] memory){
        require( msg.sender == agents[agentId - 1].adr, "Identity of user is not confirmed." );

        uint[] memory ids = new uint[](agentUnconfirmedOrders[agentId].length) ;
        bytes32[] memory infos = new bytes32[](agentUnconfirmedOrders[agentId].length) ;

        for (uint i = 0; i < agentUnconfirmedOrders[agentId].length; i++) {
            ids[i] = orders[agentUnconfirmedOrders[agentId][i] - 1].id;
            infos[i] = stringToBytes32(orders[agentUnconfirmedOrders[agentId][i] - 1].info);
        }
        return (ids, infos);
    }

    /*
    End Order part of contracts - responsible for Orders RiitRating
    */

    /*
    Begin Review part of contracts - responsible for Review RiitRating
    */

    struct userMark{
        bool isValue;
        uint16[12] currentYear;
        uint16[maxSpecNumber][12] eventsNumber;
        uint16[maxSpecNumber][12] averageMarks;
    }

    mapping(uint => userMark) public marks; // agentId to Mark;
    event AddNewReview(uint indexed authorId, uint indexed userId, uint orderId);

    function addReview(uint orderId, uint16 year, uint8 month, uint8[maxSpecNumber] memory reviewMarks) public {
        require(orderId <= orderArrayLength, "Order not not exists.");
        
        /* 
        *    We remove datetime calcilation - so these cariables coming from params
        *
        uint16 year = getYear(now);
        uint8 month = getMonth(now);
        */

        uint orderCustomerId = orders[orderId - 1].customerId;
        uint orderExecutorId = orders[orderId - 1].executorId;

        require(
            agents[orderCustomerId - 1].adr == msg.sender
            ||
            agents[orderExecutorId - 1].adr == msg.sender,
            "You do not have access to this function. Must be customer or executors of this order."
        );

        uint authorId;
        uint userId;

        if(agents[orderExecutorId - 1].adr == msg.sender  ){
            require(orders[orderId - 1].executorState == OrderState.Confirmed);
            orders[orderId - 1].executorState = OrderState.Reviewed;
            authorId = agents[orderExecutorId - 1].id;
            userId = agents[orderExecutorId - 1].id;
        }else{
            require( orders[orderId - 1].customerState == OrderState.Confirmed);
            orders[orderId - 1].customerState = OrderState.Reviewed;
            authorId = agents[orderExecutorId - 1].id;
            userId = agents[orderExecutorId - 1].id;
        }

        if(marks[userId].isValue !=  true){ // new user record
            uint16[12] memory currentYear;
            uint16[maxSpecNumber][12] memory eventsNumber;
            uint16[maxSpecNumber][12] memory averageMarks;
            //uint16[maxSpecNumber][12] memory averageWeightMarks;

            marks[userId] = userMark(true, currentYear, eventsNumber, averageMarks/*, averageWeightMarks*/);
        }
        

        if(marks[userId].currentYear[month - 1] != year ){ // srart review for new Yaar
            marks[userId].currentYear[month - 1] = year;
            
            for(uint i = 0; i < maxSpecNumber; i++){
                if(reviewMarks[i] > minAvailableMark){
                    marks[userId].eventsNumber[month - 1][i] = 1;
                    if(reviewMarks[i] > maxAvailableMark){
                        marks[userId].averageMarks[month - 1][i] = maxAvailableMark;
                    }else{
                        marks[userId].averageMarks[month - 1][i] = reviewMarks[i];
                    }
                }
            }
        }else{
            
            for(uint i= 0; i  < maxSpecNumber; i++){
               if(reviewMarks[i] > minAvailableMark){
                   if(reviewMarks[i] > maxAvailableMark){
                       marks[userId].averageMarks[month - 1][i] = (marks[userId].averageMarks[month - 1][i] * marks[userId].eventsNumber[month - 1][i] + maxAvailableMark) / (marks[userId].eventsNumber[month - 1][i] + 1);
                    }else{
                        marks[userId].averageMarks[month - 1][i] = (marks[userId].averageMarks[month - 1][i] * marks[userId].eventsNumber[month - 1][i] + reviewMarks[i]) / (marks[userId].eventsNumber[month - 1][i] + 1);
                    }
                    marks[userId].eventsNumber[month - 1][i] = marks[userId].eventsNumber[month - 1][i] + 1;
               }
            }  
        }
       
        emit AddNewReview(authorId, userId, orderId);
    }

    function getUserReviewInfo( uint userId) public view returns(
        bool,
        uint16[12] memory,
        uint16[maxSpecNumber][12] memory,
        uint16[maxSpecNumber][12] memory
    ){
        bool isValue  = marks[userId].isValue;
        uint16[12] memory currentYear  = marks[userId].currentYear;
        uint16[maxSpecNumber][12] memory eventsNumber  = marks[userId].eventsNumber;
        uint16[maxSpecNumber][12] memory averageMarks  = marks[userId].averageMarks;

        return (isValue, currentYear, eventsNumber, averageMarks/*, averageWeightMarks*/);
    }

   

    function getAverageById(uint userId) public view returns( uint16 ){
        require(userId <= agentArrayLength, "User not exists.");

        if(marks[userId].isValue == false){
            return maxAvailableMark;
        }

        userMark memory currentMark = marks[userId];
        uint16 totalMark = 0;
        uint16 totalPower = 0;

        for( uint i = 0; i < specArrayLength; i++){
            uint totalSpec = 0;

            for( uint j = 0; j < 12; j++){
                totalSpec = totalSpec + currentMark.averageMarks[j][i];
            }
            totalMark = totalMark + (uint16)(totalSpec * specification[i].power);
            totalPower = totalPower + specification[i].power;
        }
        return totalMark / totalPower;
    }
   
    /*
    End Review part of contracts - responsible for Review RiitRating
    */

}
