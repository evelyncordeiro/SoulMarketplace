// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "https://github.com/masa-finance/masa-contracts-identity/blob/3db3fb41640c7c4a2a17aa315daea9215dcf6bc9/contracts/SoulName.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract soulMarketplace is Ownable, Pausable, ReentrancyGuard {
    ISoulName public soulNameContract;
    ISoulboundIdentity public soulIdentityContract;

    using SafeMath for uint;

    uint  commissionPercentage = 350;
    uint comissionAmount;
    uint sellerAmount;

    constructor(address _soulNameContract, address _soulIdentityContract) {
        soulNameContract = ISoulName(_soulNameContract);
        soulIdentityContract = ISoulboundIdentity(_soulIdentityContract);
    }

    struct soulListing {  
        uint256 listId;
        address seller;
        bool forSale;
    }
    
    // Events
    event deposit(address indexed contractAddress, address indexed from, uint amount);
    event donationAmount( address _donator, uint256 _listId, uint256 _amount);
    event soulList(address _seller, uint256 _listId);


    mapping(uint256 => soulListing) public listings;

        //Fallback function
    fallback () external payable {
        emit deposit(address(this), msg.sender, msg.value);
    } 

    //Receive function
    receive () external payable {
        emit deposit(address(this), msg.sender, msg.value);
    }


    //Pause
    function pause() public onlyOwner {
        _pause();
    }

    //Unpause
    function unpause() public onlyOwner {
        _unpause();
    }  

    // update comission percentage
    function updateComissionPercentage(uint256 _value) public onlyOwner{
        commissionPercentage = _value;
    }

    function mintSoulName(address _to, string memory _name, uint256 _yearsPeriod, string memory _tokenURI ) public {

        soulNameContract.mint(_to, _name, _yearsPeriod, _tokenURI);
    }

    function mintIdentity(address _to) public {
        soulIdentityContract.mint(_to);
    }



    // this function will list the document into the marketplace
  function list( uint256 _listId) public  {
    listings[_listId] = soulListing(
       _listId,
       msg.sender, 
       true
       );
     emit soulList(msg.sender,  _listId) ;


  }

  
    // this function will cancel the listing.

  function cancel( uint256 _listId) public {      
     soulListing storage listing = listings[_listId];
     require(listing.seller == msg.sender, "is not the seller");
     require(listing.forSale == true, "is not listened");
     listing.forSale = false;
  }

         // Function to transfer or withdraw the funds
    function withdraw (uint _amount) public whenNotPaused onlyOwner {
        require(_amount != 0, "Amount cannot be zero");
        require(_amount <= address(this).balance, "Insufficient funds.");
        payable(msg.sender).transfer(_amount);
    }

    // Donation
    function donation( uint256 _listId,  uint256 _amount) public payable whenNotPaused nonReentrant {
        soulListing storage listing = listings[_listId];
        require(listing.forSale != false, "item is not for sell");
        require(listing.seller != msg.sender, "You cannot buy your own document");
        require(msg.value > 0," amount need to be more then 0");
        comissionAmount = _amount.mul(commissionPercentage).div(10000);
        sellerAmount = _amount.sub(comissionAmount);

        payable(listing.seller).transfer(sellerAmount);
        emit donationAmount( msg.sender, _listId, sellerAmount);
    }

    function soulIsAvailable(string memory _name) public view returns (bool) {
        return soulNameContract.isAvailable (_name);
    }

    function soulGetTokenData(string memory _name) public view returns (string memory, bool, uint256, uint256, uint256, bool) {
        return soulNameContract.getTokenData(_name);
    }

    function soulGetTokenId(string memory _name) public view returns (uint256){
        return soulNameContract.getTokenId(_name) ;
    }

    function soulGetSoulNames(address _owner) public view returns (string[] memory) {
        return soulNameContract.getSoulNames(_owner);
    }

    // get comission percentage
    function getComissionPercentage() public view returns (uint256){
      return commissionPercentage;
    }

}


