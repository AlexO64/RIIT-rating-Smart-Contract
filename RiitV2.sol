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
    
    
}