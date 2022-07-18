// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract DrippyZombies is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI = "";
    string public uriSuffix = ".json";
    
    uint256 public maxSupply = 8000;
   
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


    /// @dev Function multi mint.
    /// @param _mintAmount Number of amount NFTs owner want to mint.
    function batchMint(uint256 _mintAmount) public onlyOwner {
        _mintLoop(msg.sender, _mintAmount);
    }

    /// @dev Function transfer owner token to market contract after mint.
    /// @param _receiver Market contract that receive NFTs from owner.
    /// @param _amount Number of amount NFTs owner want to transfer to Market contract.
    function batchTransfer(address _receiver, uint256 _amount)
        external
        onlyOwner
    {
        uint256 ownerBalance = balanceOf(owner());
        require(
            ownerBalance >= _amount,
            "Max supply exceeded!"
        );
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner(), 0);
            safeTransferFrom(owner(), _receiver, tokenId);
        }
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

    /// @dev Function check all current tokenId of the _owner address.
    /// @param _owner Address wallet that want to get.
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
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
  

    function withdraw() public onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
         uint256 supply = totalSupply();
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
