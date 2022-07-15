// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IDrippyZombies {
    function getStatus() external view returns (bool) ;
    function totalSupply() external view returns (uint256);
    function getMaxSupply() external view returns (uint256);
}

contract MarketPlace is ERC721Holder, Ownable {
    address public erc721;
    address[] private whitelistedAddresses;
    uint256 public maxMintAmountPerTx = 1;
    uint256 public maxMintAmountPreSalePerAddress = 4; // Presale
    uint256 public maxMintAmountPublicPerAddress = 6; // public sale
    uint256 public preSaleCost = 0.04 ether;
    uint256 public publicSaleCost = 0.08 ether;

    uint32 preSaleStartTime;
    uint32 publicSaleStartTime;

    // event MarketItemCreated (
    //     uint indexed itemId,
    //     address indexed nftContract,
    //     uint256 indexed tokenId,
    //     address seller,
    //     address owner,
    //     uint256 price
    // );


    constructor(address _nftContract) {
        erc721 = _nftContract;
    }

   
    function setWhitelist(address[] calldata _addressArray) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _addressArray;
    }

    // Decide when the presale starts
    function setPreSaleStartTime(uint32 timestamp) external onlyOwner {
        preSaleStartTime = timestamp;
    }

    // Decide when the public starts
    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        publicSaleStartTime = timestamp;
    }
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setmaxMintAmountPreSalePerAddress(uint256 _newmaxMintAmount)
        public
        onlyOwner
    {
        maxMintAmountPreSalePerAddress = _newmaxMintAmount;
    }

    function setmaxMintAmountPublichSalePerAddress(uint256 _newmaxMintAmount)
        public
        onlyOwner
    {
        maxMintAmountPublicPerAddress = _newmaxMintAmount;
    }

    function setPreSaleCost(uint256 _cost) public onlyOwner {
        preSaleCost = _cost;
    }

    function setPublicSaleCost(uint256 _cost) public onlyOwner {
        publicSaleCost = _cost;
    }

    function isAddressWhitelisted(address _user) private view returns (bool) {
        uint256 i = 0;
        while (i < whitelistedAddresses.length) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
            i++;
        }
        return false;
    }

    modifier onWhiteList() {
        require(isAddressWhitelisted(msg.sender), "Not on the whitelist!");
        _;
    }
    modifier maxMintAmount(uint256 _mintAmount) {
        require(
            IERC721(erc721).balanceOf(msg.sender) + _mintAmount <
                maxMintAmountPreSalePerAddress + 1,
            "Max mint per address exceeded!"
        );
        _;
    }
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount < maxMintAmountPerTx + 1,
            "Invalid mint amount!"
        );
        require(
            IDrippyZombies(erc721).totalSupply() + _mintAmount < IDrippyZombies(erc721).getMaxSupply() + 1,
            "Max supply exceeded!"
        );
        if (whitelistedAddresses.length > 0) {
            require(isAddressWhitelisted(msg.sender), "Not on the whitelist!");
        }
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

    modifier minMintAmount(uint256 _mintAmount) {
         require(_mintAmount > 0, "Minimum mint per address exceeded!");
        _;
    }
    modifier activeContract() {
        require(!IDrippyZombies(erc721).getStatus(), "The contract is paused!");
        _;
    }
   
    function buyNFTPresale(uint256 _tokenId) external payable  activeContract insufficientFunds(preSaleCost, 1) saleStartTime(preSaleStartTime)   minMintAmount(1) maxMintAmount(1) onWhiteList {
        getOwner().transfer(msg.value);
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function getOwner() public view returns (address payable)  {
        return payable(owner());
    }

    function getStatus() public view returns (bool)  {
        return IDrippyZombies(erc721).getStatus();
    }

}
