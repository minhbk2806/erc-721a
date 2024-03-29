// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IDrippyZombies is IERC721Enumerable {
    function getPaused() external view returns (bool) ;
    function getMaxSupply() external view returns (uint256);
}

contract MarketPlace is ERC721Holder, Ownable {
    address public erc721;
    mapping(address => bool) public whitelistedAddresses;
    uint256 public maxMintAmountPerTx = 1;
    uint256 public maxMintAmountPreSalePerAddress = 4; // Presale
    uint256 public maxMintAmountPublicPerAddress = 6; // public sale
    uint256 public preSaleCost = 0.04 ether;
    uint256 public publicSaleCost = 0.08 ether;

    uint32 public preSaleStartTime;
    uint32 public publicSaleStartTime;

    event BuyNFT (
        uint256 indexed tokenId,
        address indexed nftContract,
        address seller,
        address owner,
        uint256 price
    );


    constructor(address _nftContract) {
        erc721 = _nftContract;
    }

    /// @dev Function set whitelist who can buy token in presale.
    /// @param _addresses Array of wallet address who will can buy token in presale.
    /// @param _status Array of status for each wallet address.
    function setWhitelist(address[] calldata _addresses, bool[] calldata _status) public onlyOwner {
        require(_addresses.length == _status.length, "Invalid array address");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = _status[i];
        }
    }

    /// @dev Function Decide when the presale starts
    /// @param timestamp Timestamp start presale.
    function setPreSaleStartTime(uint32 timestamp) external onlyOwner {
        preSaleStartTime = timestamp;
    }

    /// @dev Function Decide when the public starts
    /// @param timestamp Timestamp start publicsale.
    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        publicSaleStartTime = timestamp;
    }

    /// @dev Function set max mint amount per transaction
    /// @param _maxMintAmountPerTx Max mint amount.
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /// @dev Function set max mint amount in presale per address
    /// @param _newmaxMintAmount Max mint amount.
    function setmaxMintAmountPreSalePerAddress(uint256 _newmaxMintAmount)
        public
        onlyOwner
    {
        maxMintAmountPreSalePerAddress = _newmaxMintAmount;
    }

    /// @dev Function set max mint amount in publicsale per address
    /// @param _newmaxMintAmount Max mint amount.
    function setmaxMintAmountPublichSalePerAddress(uint256 _newmaxMintAmount)
        public
        onlyOwner
    {
        maxMintAmountPublicPerAddress = _newmaxMintAmount;
    }

    /// @dev Function set presale cost per token
    /// @param _cost cost.
    function setPreSaleCost(uint256 _cost) public onlyOwner {
        preSaleCost = _cost;
    }

    /// @dev Function set public cost per token
    /// @param _cost cost.
    function setPublicSaleCost(uint256 _cost) public onlyOwner {
        publicSaleCost = _cost;
    }

    modifier onWhiteList() {
        require(whitelistedAddresses[msg.sender] == true, "Not on the whitelist!");
        _;
    }
    modifier maxMintAmount(uint256 _mintAmount, uint256 checkedValue) {
        require(
            IERC721(erc721).balanceOf(msg.sender) + _mintAmount <
                checkedValue + 1,
            "Max mint per address exceeded!"
        );
        _;
    }

    modifier mintPerTx(uint256 _mintAmount) {
        require(
            _mintAmount < maxMintAmountPerTx + 1,
            "Invalid mint amount!"
        );
        _;
    }

    modifier insufficientFunds(uint256 _tokenPrice, uint256 _mintAmount) {
        require(msg.value >= _tokenPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier saleStartTime(uint256 _startTime) {
        uint256 _saleStartTime = uint256(_startTime);
        // It can mint when the pre sale begins.
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        _;
    }

    modifier saleEndTime(uint256 _endTime) {
        uint256 _saleEndTime = uint256(_endTime);
        require(
            _saleEndTime != 0 && block.timestamp <= _saleEndTime,
            "sale has end"
        );
        _;
    }

    modifier minAmount(uint256 _mintAmount) {
         require(_mintAmount > 0, "Minimum mint per address exceeded!");
        _;
    }
    modifier activeContract() {
        require(!getPaused(), "The contract is paused!");
        _;
    }
  
    /// @dev Function buyer buy a token by  _tokenId
    /// @param _tokenId Id of token
    function buyNFT(uint256 _tokenId) 
        external 
        payable  
        activeContract 
        insufficientFunds(publicSaleCost, 1) 
        saleStartTime(publicSaleStartTime)   
        minAmount(1) 
    {
        payable(getOwner()).transfer(msg.value);
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit BuyNFT (
            _tokenId,
            erc721,
            address(this),
            msg.sender,
            publicSaleCost
        );
    }

    function transferOwnershipTokens(uint256 _amount) 
        private 
    {
        uint256 ownerBalance = IERC721(erc721).balanceOf(address(this));
        require(
            ownerBalance > _amount,
            "Max supply exceeded!"
        );
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = IDrippyZombies(erc721).tokenOfOwnerByIndex(address(this), 0);
            IERC721(erc721).safeTransferFrom(address(this), msg.sender, tokenId);
        }
        payable(getOwner()).transfer(msg.value);
    }

    /// @dev Function buyer buy when public sale start
    /// @param _amount Amount of token buyer want to buy.
    function buyNFTPublicSale(uint256 _amount) 
        public 
        payable  
        activeContract 
        insufficientFunds(publicSaleCost, _amount) 
        saleStartTime(publicSaleStartTime)
        minAmount(_amount) 
        mintPerTx(_amount) 
        maxMintAmount(_amount, maxMintAmountPublicPerAddress) 
    {
        transferOwnershipTokens(_amount);
    }

    /// @dev Function buyer buy when presale start
    /// @param _amount Amount of token buyer want to buy.
    function buyNFTPresale(uint256 _amount) 
        public 
        payable  
        activeContract 
        insufficientFunds(preSaleCost, _amount) 
        saleStartTime(preSaleStartTime)   
        saleEndTime(publicSaleStartTime)
        minAmount(_amount) 
        mintPerTx(_amount) 
        maxMintAmount(_amount, maxMintAmountPreSalePerAddress) 
        onWhiteList 
    {
        transferOwnershipTokens(_amount);
    }

    function getPaused() public view returns (bool)  {
        return IDrippyZombies(erc721).getPaused();
    }

    function withdrawNFT(uint256 _tokenId, address _receiver) external onlyOwner {
       IERC721(erc721).safeTransferFrom(address(this), _receiver, _tokenId);
       
    }

    function withdrawAllNFTs(address _receiver) external onlyOwner {
        uint256 _amounts = IERC721Enumerable(erc721).balanceOf(address(this));
        for (uint256 i = 0; i < _amounts; i++) {
            uint256 _tokenId = IERC721Enumerable(erc721).tokenOfOwnerByIndex(address(this), 0);
            IERC721(erc721).safeTransferFrom(address(this), _receiver, _tokenId);
        }
       
    }
     function getOwner() public view returns (address payable)  {
        return payable(owner());
    }


}
