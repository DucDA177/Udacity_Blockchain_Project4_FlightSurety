pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    
    address[] public passengerAddresses;

    uint8 private constant MultiPartyConsensus = 4;
    uint256 public constant PriceOfInsurance = 1 ether;
    uint256 public constant MinFund = 10 ether;
    
    uint256 public noOfAirlines = 0;

    struct Airline {
        address walletAddress,
        string name;
        uint256 votes;
        uint256 funds;
    }
    

    struct Passenger {
        address walletAddress;
        mapping(string => uint256) boughtFlight;
        uint256 credit;
    }
    
    mapping(address => uint256) private authorizedAddress;
    mapping(address => Airline) private airlines;
    mapping(address => Passenger) private passengers;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;
        
        airlines[msg.sender] = Airline({
            walletAddress: contractOwner,
            name: "Number 1",
            funded: 0,
            votes: 0
        });
        noOfAirlines++;

        authorizedAddress[msg.sender] = 1;
        passengerAddresses = new address[](0);

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

    modifier requireIsCallerAuthorized() {
        require(authorizedAddress[msg.sender] == 1, "Not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

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

    function isAirlineActive (address walletAddress) public view returns(bool) {
        return(airlines[walletAddress].funded >= MinFund);
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
                                address walletAddress,
                                string name
                            )
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            
    {
        
        if (noOfAirlines < MultiPartyConsensus) {
            airlines[walletAddress]  = Airline({
                                                walletAddress: walletAddress,
                                                name: name,
                                                funded: 0,
                                                votes: 1
                                        });
            noOfAirlines++;
        }
        else 
            airlines[airlineAddress].votes++;
        
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
            ( 
                string flight                            
            )
            external
            requireIsOperational
            payable
    {
          if (msg.value > PriceOfInsurance) 
            msg.sender.transfer(PriceOfInsurance);
      
        passengers[msg.sender].boughtFlight[flight] = msg.value;

      
        
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                (
                    string flight
                )
                external
                
    {
        for (uint256 i = 0; i < passengerAddresses.length; i++) {

            passenger = passengers[passengerAddresses[i]]

            if (passenger.boughtFlight[flight] != 0) {

                uint256 currentCredit = passenger.credit;

                uint256 payedPrice = passenger.boughtFlight[flight];

                passenger.boughtFlight[flight] = 0;

                passenger.credit = currentCredit + payedPrice + payedPrice.div(2);

            }
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                (
                    address passengerAddress
                )
                external
                returns (uint256, uint256, uint256, uint256, address, address)
    {
        require(passengers[passengerAddress].credit > 0, "Not enough credit");

        uint256 oldBalance = address(this).balance;
        uint256 credit = passengers[passengerAddress].credit;

        require(address(this).balance > credit, "Not enough fund");

        passengers[passengerAddress].credit = 0;
        passengerAddress.transfer(credit);

        uint256 finalCredit = passengers[passengerAddress].credit;

        return (oldBalance, credit, address(this).balance, finalCredit, passengerAddress, address(this));
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public
    requireIsOperational
    payable
    {
        uint256 currentFund = airlines[msg.sender].funded;
        airlines[msg.sender].funded = currentFund.add(msg.value);
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
        fund();
    }


}