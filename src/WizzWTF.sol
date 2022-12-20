//
// WizzmasArtwork
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";

contract WizzWTF is ERC1155, Owned {
    string public name = 'Wizz WTF';
    string public symbol = 'WIZZ';

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => bool) public minters;

    error NotOwnerOrMinter();
    error MissingToken();
    error InvalidMintAmount();

    modifier onlyMinterOrOwner() {
        if (!minters[msg.sender] && msg.sender != owner) revert NotOwnerOrMinter();
        _;
    }

    constructor(address _owner) Owned(_owner) {}

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(tokenURIs[id]).length <= 0) revert MissingToken();
        return tokenURIs[id];
    }

    function addMinter(address minter) public onlyOwner {
        minters[minter] = true;
    }

    function mint(
        address initialOwner,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public onlyMinterOrOwner {
        if (amount <= 0) revert InvalidMintAmount();
        tokenSupply[tokenId] = tokenSupply[tokenId] + amount;
        _mint(initialOwner, tokenId, amount, data);
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        emit URI(tokenUri, tokenId);
        tokenURIs[tokenId] = tokenUri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}