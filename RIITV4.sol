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
    /*
    Begin DateTime Parts of contract
    */
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
            uint16 year;
            uint8 month;
            uint8 day;
            uint8 hour;
            uint8 minute;
            uint8 second;
            uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
            if (year % 4 != 0) {
                    return false;
            }
            if (year % 100 != 0) {
                    return true;
            }
            if (year % 400 != 0) {
                    return false;
            }
            return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
            if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                    return 31;
            }
            else if (month == 4 || month == 6 || month == 9 || month == 11) {
                    return 30;
            }
            else if (isLeapYear(year)) {
                    return 29;
            }
            else {
                    return 28;
            }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
            uint secondsAccountedFor = 0;
            uint buf;
            uint8 i;

            // Year
            dt.year = getYear(timestamp);
            buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
            secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

            // Month
            uint secondsInMonth;
            for (i = 1; i <= 12; i++) {
                    secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                    if (secondsInMonth + secondsAccountedFor > timestamp) {
                            dt.month = i;
                            break;
                    }
                    secondsAccountedFor += secondsInMonth;
            }

            // Day
            for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                    if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                            dt.day = i;
                            break;
                    }
                    secondsAccountedFor += DAY_IN_SECONDS;
            }

            // Hour
            dt.hour = getHour(timestamp);

            // Minute
            dt.minute = getMinute(timestamp);

            // Second
            dt.second = getSecond(timestamp);

            // Day of week.
            dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint16) {
            uint secondsAccountedFor = 0;
            uint16 year;
            uint numLeapYears;

            // Year
            year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
            numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
            secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

            while (secondsAccountedFor > timestamp) {
                    if (isLeapYear(uint16(year - 1))) {
                            secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            secondsAccountedFor -= YEAR_IN_SECONDS;
                    }
                    year -= 1;
            }
            return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
            return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
            uint16 i;

            // Year
            for (i = ORIGIN_YEAR; i < year; i++) {
                    if (isLeapYear(i)) {
                            timestamp += LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            timestamp += YEAR_IN_SECONDS;
                    }
            }

            // Month
            uint8[12] memory monthDayCounts;
            monthDayCounts[0] = 31;
            if (isLeapYear(year)) {
                    monthDayCounts[1] = 29;
            }
            else {
                    monthDayCounts[1] = 28;
            }
            monthDayCounts[2] = 31;
            monthDayCounts[3] = 30;
            monthDayCounts[4] = 31;
            monthDayCounts[5] = 30;
            monthDayCounts[6] = 31;
            monthDayCounts[7] = 31;
            monthDayCounts[8] = 30;
            monthDayCounts[9] = 31;
            monthDayCounts[10] = 30;
            monthDayCounts[11] = 31;

            for (i = 1; i < month; i++) {
                    timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
            }

            // Day
            timestamp += DAY_IN_SECONDS * (day - 1);

            // Hour
            timestamp += HOUR_IN_SECONDS * (hour);

            // Minute
            timestamp += MINUTE_IN_SECONDS * (minute);

            // Second
            timestamp += second;

            return timestamp;
    }
    /*
    End DateTime Parts od contract
    */
    uint constant private maxSpecNumber = 8; //Max Available number characteristics
   uint8 constant private minAvailableMark = 1; //Max mark
    uint8 constant private maxAvailableMark = 100; //Max mark
    
    constructor( ) public {
        specArrayLength = 0;
        agentArrayLength = 0;
        orderArrayLength = 0;
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
   
    function ConfirmOrderByCustomer( uint id ) private {
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
   
    function ConfirmOrderByExecutor( uint id ) private {
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
    struct userMark{
       uint8 averageRate;
       uint8 averageWeightRate;
       
       uint16[12] currentYear;
       uint16[maxSpecNumber][12] eventsNumber;
       uint8[maxSpecNumber][12] averageMarks;
       uint8[maxSpecNumber][12] averageWeightMarks;
    }
    
    mapping(uint => userMark) public marks; // agentId to Mark;
    event AddNewReview(uint indexed authorId, uint indexed userId, uint orderId);
    
    function addReview(uint orderId, uint8[maxSpecNumber] memory newMarks) public {
        require(orderId <= orderArrayLength, "Order not not exists.");
        
        Order memory order = orders[orderId - 1];
        require(
            agents[order.executorId - 1].adr == msg.sender
            ||
            agents[order.customerId - 1].adr == msg.sender,
            "You do not have access to this function. Must be customer or executors of this order."
        );
       
        uint authorId;
        uint userId;
         
        
        if(agents[order.executorId - 1].adr == msg.sender  ){
            authorId = agents[order.customerId - 1].id;
            userId = agents[order.executorId - 1].id;
        }else{
            authorId = agents[order.executorId - 1].id;
            userId = agents[order.customerId - 1].id;
        }
        
        uint8 authorWeightedRate = (marks[authorId].averageRate == 0? maxAvailableMark : marks[authorId].averageWeightRate); // check that object already exists
            
        
        uint16 year = getYear(now);
        uint8 month = getMonth(now);
        
        if(marks[userId].averageRate == 0 ){ // first review for user
            userMark memory newMark;
            
            newMark.currentYear[month] = year;
            for( uint i = 0; i <= specArrayLength; i++){
                if(newMarks[i] < minAvailableMark){
                    continue; // 0 means no mark setup for review
                }
                newMark.eventsNumber[month][i] = 1;
                if(newMarks[i] > maxAvailableMark){
                    newMark.averageMarks[month][i] = maxAvailableMark;
                    newMark.averageWeightMarks[month][i] = maxAvailableMark;
                }else{
                    newMark.eventsNumber[month][i] = 1;
                    newMark.averageMarks[month][i] = newMarks[i];
                    newMark.averageWeightMarks[month][i] = maxAvailableMark - ( (maxAvailableMark - newMarks[i]) * authorWeightedRate / maxAvailableMark );
                }
            } 
            marks[userId] = newMark;
        }
        emit AddNewReview(authorId, userId, orderId);
    }
    
    /*
    End Review part of contracts - responsible for Review RiitRating
    */
   
}
