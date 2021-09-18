pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
    //using SafeMath for uint8;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => bool) private authorizedAddress;

    //begin Airline
    struct Airline{
        bool is_registered;
        bool is_funded;
        uint256 votes;
    }
    //Consensus data
    mapping (address=>address[]) private consensusMap;

    mapping(address => Airline) public airlines;
    uint256 private count_airlines;
    address public first_airline;
    
    //end Airline

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
     event airline_registered(address airline);
     event airline_funded(address airline);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address original_airline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        authorizedAddress[contractOwner] = true;
        airlines[original_airline].is_registered =true;
        airlines[original_airline].is_funded = false;
        first_airline = original_airline;
        count_airlines = 1;

    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the an authoriezed account to be the function caller
    */
    modifier callerAuthorized() 
    {
        require(authorizedAddress[msg.sender] == true, "Address not authorized to call this function");
        _;
    }

    
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    
    /**
    * @dev function that requires the calling address to be authorized
    */
    function get_airline_count() 
                                public
                                view returns(uint256)

    {
        return count_airlines;
    }
    /**
    * @dev function to check if airline is funded
    */
    function is_funded_airline(address check_airline) 
                                public
                                view 
                                returns(bool)

    {
        bool funded = false;
        if(airlines[check_airline].is_funded){
            funded = true;
        }
        return funded;
    }
    /**
    * @dev function to add airline
    */
    function get_airline_vote_count(address look_up_airline) 
                                public
                                view 
                                returns(uint256)

    {
        return consensusMap[look_up_airline].length;
    }
    /**
    * @dev function to add airline
    */
    function setAirlineAsRegistered(address authorize) 
                            payable
                            external
    {
        airlines[authorize].is_registered = true;
        count_airlines = count_airlines.add(1);
    }
    /**
    * @dev function to get the array of ailine sponsors for mulit-party logic
    */
    function get_airline_sponsor_array(address airline_to_check) 
                            public
                            view
                            returns(address[] memory)
    {
        address[] memory tmp_out = new address[] (consensusMap[airline_to_check].length);
        for(uint i =0; i < consensusMap[airline_to_check].length; i++){
            tmp_out[i] = consensusMap[airline_to_check][i];
        }
        
        return tmp_out;
        
    }
    /**
    * @dev function to get the array of ailine sponsors for mulit-party logic
    */
    function add_vote_for_airline(address for_airline, address sponsor) 
                            public
                            
                            returns(uint256)
    {
        
        
        consensusMap[for_airline].push(sponsor);
        airlines[for_airline].votes = airlines[for_airline].votes.add(1);

        return  consensusMap[for_airline].length;
        
    }
    /**
    * @dev Get operating status of contract
    *
    * @return confirms status as airline
    */      
    function isAirline(address check_airline) 
                            public 
                            view 
                            returns(bool) 
    {
        bool found = false;
        if(airlines[check_airline].is_registered){
            found = true;
        }
        return found;
    }
    /**
    * @dev function that requires the calling address to be authorized
    */
    function authorizeCaller(address callerAddress)
                                                    public
                                                    
    {
        authorizedAddress[callerAddress] = true;
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            ( 
                              address airline   
                            )
                            public
                            returns(bool)
    {
       airlines[airline].is_registered = true;
       count_airlines = count_airlines.add(1);

       emit airline_registered(airline);

       return true;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address airline_to_fund
                            )
                            public
                            payable
    {
        airlines[airline_to_fund].is_funded = true;
        airlines[airline_to_fund].is_registered = false;
        airlines[airline_to_fund].votes = 0;
        emit airline_funded(airline_to_fund);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        require(msg.data.length == 0);
        fund(msg.sender);
    }


}

