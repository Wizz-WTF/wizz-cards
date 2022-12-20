//
// WizzmasCardMinter
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "solmate/tokens/ERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/auth/Owned.sol";

interface ArtworkContract {
    function tokenSupply(uint256 tokenId) external returns (uint256);

    function mint(
        address initialOwner,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract WizzWTFMinter is Owned, ReentrancyGuard {
    address public wizzmasArtworkAddress;
    uint256 public numArtworkTypes;

    bool public mintEnabled = false;
    uint256 public mintPrice = (1 ether * 0.01);
    uint256 public freeMintsPerAddress = 1;
    mapping(address => uint) public minted;
    mapping(uint256 => bool) public tokenFrozen;

    event WizzmasArtworkMinted(address minter, uint256 artworkType);
    event WizzmasArtworkClaimed(address claimer, uint256 artworkType);

    constructor(address _artworkAddress, uint256 _numArtworkTypes, address _owner) Owned(_owner) {
        wizzmasArtworkAddress = _artworkAddress;
        numArtworkTypes = _numArtworkTypes;
    }

    function canClaim(address claimer) public view returns (bool) {
        return minted[claimer] < freeMintsPerAddress;
    }

    function claim(uint256 artworkType) public nonReentrant {
        require(mintEnabled, "MINT_CLOSED");
        require(!tokenFrozen[artworkType], "TOKEN_FROZEN");
        require(canClaim(msg.sender), "FREE_CLAIMS_USED");
        ArtworkContract artwork = ArtworkContract(wizzmasArtworkAddress);
        require(artworkType < numArtworkTypes, "INCORRECT_ARTWORK_TYPE");

        artwork.mint(msg.sender, artworkType, 1, "");

        minted[msg.sender] += 1;

        emit WizzmasArtworkClaimed(msg.sender, artworkType);
    }

    function mint(uint256 artworkType) public payable nonReentrant {
        require(mintEnabled, "MINT_CLOSED");
        require(!tokenFrozen[artworkType], "TOKEN_FROZEN");
        require(msg.value == mintPrice, "INCORRECT_ETH_VALUE");
        ArtworkContract artwork = ArtworkContract(wizzmasArtworkAddress);
        require(artworkType < numArtworkTypes, "INCORRECT_ARTWORK_TYPE");

        artwork.mint(msg.sender, artworkType, 1, "");

        minted[msg.sender] += 1;

        emit WizzmasArtworkMinted(msg.sender, artworkType);
    }

    // Only contract owner shall pass
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMintEnabled(bool _newMintEnabled) public onlyOwner {
        mintEnabled = _newMintEnabled;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setFreeMintsPerAddress(uint256 _numMints) public onlyOwner {
        freeMintsPerAddress = _numMints;
    }

    function setFreezeToken(uint256 _tokenId, bool freeze) public onlyOwner {
        tokenFrozen[_tokenId] = freeze;
    }

    function setNumArtworkTypes(uint256 _artworkTypeMax) public onlyOwner {
        numArtworkTypes = _artworkTypeMax;
    }
}
