// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


pragma solidity >=0.7.0 <0.9.0;

contract DrippyZombies is ERC721, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string public baseURI = "";
    string public uriSuffix = ".json";
    
    uint256 public maxSupply = 8000;

    mapping(address => bool) public whitelistedAddresses;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public maxMintAmountPreSalePerAddress = 4; // Presale
    uint256 public maxMintAmountPublicPerAddress = 6; // public sale
    uint256 public preSaleCost = 0.029 ether;
    uint256 public publicSaleCost = 0.05 ether;

    uint32 public preSaleStartTime;
    uint32 public publicSaleStartTime;
   
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setUriSuffix(".json");
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier activeContract() {
        require(!paused, "The contract is paused!");
        _;
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
            balanceOf(msg.sender) + _mintAmount <
                checkedValue + 1,
            "Max mint per address exceeded!"
        );
        _;
    }
    modifier mintPerTx(uint256 _mintAmount) {
        require(
            _mintAmount < maxMintAmountPerTx + 1,
            "Invalid max min amount per transaction!"
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



    /// @dev Function multi mint.
    /// @param _mintAmount Number of amount NFTs owner want to mint.
    function batchMint(uint256 _mintAmount) public onlyOwner {
        _mintLoop(msg.sender, _mintAmount);
    }


    /// @dev Function multi mint from special address.
    /// @param _receiver Address wallet that receive NFTs from owner.
    /// @param _mintAmount Number of amount NFTs owner want to mint to _receiver.
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _mintLoop(_receiver, _mintAmount);
    }

    /// @dev Function buyer buy when presale start
    /// @param _mintAmount Amount of token buyer want to buy.
    function preSaleMint(uint256 _mintAmount)
        external
        payable
        activeContract 
        insufficientFunds(preSaleCost, _mintAmount) 
        saleStartTime(preSaleStartTime)   
        saleEndTime(publicSaleStartTime)
        minAmount(_mintAmount) 
        mintPerTx(_mintAmount) 
        maxMintAmount(_mintAmount, maxMintAmountPreSalePerAddress) 
        onWhiteList 
    {
        _mintLoop(msg.sender, _mintAmount);
    }

    /// @dev Function buyer buy when public sale start
    /// @param _mintAmount Amount of token buyer want to buy.
    function publicSaleMint(uint256 _mintAmount) 
        public 
        payable  
        activeContract 
        insufficientFunds(publicSaleCost, _mintAmount) 
        saleStartTime(publicSaleStartTime)
        minAmount(_mintAmount) 
        mintPerTx(_mintAmount) 
        maxMintAmount(_mintAmount, maxMintAmountPublicPerAddress) 
    {
        _mintLoop(msg.sender, _mintAmount);
    }


    /// @dev Function check all current tokenId of the _owner address.
    /// @param _owner Address wallet that want to get.
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 currentIndex;
        for (uint256 i; i < ownerTokenCount; i++) {
             if (ownerOf(i) == _owner) {
                tokenIds[currentIndex++] = uint256(i);
            }
            // tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /// @dev Function return metadate uri of a token ID.
    /// @param _tokenId token ID.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
  

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function getPaused() external view returns (bool)  {
        return paused;
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }
  

    function withdraw() public onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        uint256 currentSupply = supply.current();
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, currentSupply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
