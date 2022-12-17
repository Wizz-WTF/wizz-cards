// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WizzmasArtwork.sol";
import "../src/WizzmasArtworkMinter.sol";
import "../src/WizzmasCard.sol";
import "solmate/tokens/ERC721.sol";

import "forge-std/console2.sol";

// Fake Wizards contract for testing
contract DummyERC721 is ERC721 {
    constructor() ERC721("Dummy", "Dummy") {}

    uint256 counter = 0;

    function mint() public {
        _safeMint(msg.sender, counter++);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return 'testuri';
    }
}

contract WizzmasTest is Test {
    DummyERC721 public wizards;
    DummyERC721 public souls;
    DummyERC721 public warriors;
    DummyERC721 public ponies;
    DummyERC721 public beasts;
    DummyERC721 public spawn;

    WizzmasArtwork public artwork;
    WizzmasArtworkMinter public artworkMinter;
    WizzmasCard public card;

    address owner;
    address ZERO_ADDRESS = address(0);
    address spz = address(1);
    address jro = address(2);

    string cardBaseURI = "cardsURI/";
    string artworkBaseURI = "artworkURI/";

    string validMessage = 'Happy Holidays! Eat plenty of Jelly Donuts!';
    string invalidMessage = 'Happy Holidays! Eat plenty of Jelly Donuts! And watch the Kobold Koolaid its been spiked!';

    function setUp() public {
        owner = address(this);

        wizards = new DummyERC721();
        souls = new DummyERC721();
        warriors = new DummyERC721();
        ponies = new DummyERC721();
        beasts = new DummyERC721();
        spawn = new DummyERC721();

        artwork = new WizzmasArtwork(owner);
        artwork.setTokenURI(0, string.concat(artworkBaseURI, "0"));
        artwork.setTokenURI(1, string.concat(artworkBaseURI, "1"));
        artwork.setTokenURI(2, string.concat(artworkBaseURI, "2"));
        artworkMinter = new WizzmasArtworkMinter(address(artwork), 3, owner);
        artwork.addMinter(address(artworkMinter));
        address[] memory supportedTokens = new address[](6);
        supportedTokens[0] = address(wizards);
        supportedTokens[1] = address(souls);
        supportedTokens[2] = address(warriors);
        supportedTokens[3] = address(ponies);
        supportedTokens[4] = address(beasts);
        supportedTokens[5] = address(spawn);

        card = new WizzmasCard(
            address(artwork),
            supportedTokens,
            1,
            cardBaseURI,
            msg.sender
        );
    }

    function testInitialState() public {
        // TODO: test states across the board
        assertEq(card.baseURI(), cardBaseURI);

        assertEq(artwork.minters(address(artworkMinter)), true);
        assertEq(artwork.tokenURIs(0), string.concat(artworkBaseURI, "0"));
        assertEq(artwork.tokenURIs(1), string.concat(artworkBaseURI, "1"));
        assertEq(artwork.tokenURIs(2), string.concat(artworkBaseURI, "2"));
    }

    function testMintArtworks() public {
        artworkMinter.setMintEnabled(true);
        uint256 price = artworkMinter.mintPrice();
        deal(spz, 10000e18);
        vm.startPrank(spz);
        artworkMinter.claim(0);
        artworkMinter.mint{value: price * 1 wei}(1);
        artworkMinter.mint{value: price * 1 wei}(2);
        vm.stopPrank();

        assertEq(artworkMinter.minted(spz), 3);
    }

    function testMintInvalidArtwork() public {
        artworkMinter.setMintEnabled(true);
        vm.expectRevert(bytes("INCORRECT_ARTWORK_TYPE"));
        vm.prank(spz);
        artworkMinter.claim(3);
    }

    function testMintCard() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        wizards.mint();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();

        assertEq(card.tokenURI(0), string.concat(cardBaseURI, "0"));
        WizzmasCard.Card memory c = card.getCard(0);
        assertEq(c.tokenContract, address(wizards));
        assertEq(c.token, 0);
        assertEq(c.artwork, 0);
        assertEq(c.message, validMessage);
        assertEq(c.sender, spz);
        assertEq(c.recipient, jro);
    }

    function testStrikeMessage() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        wizards.mint();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();

        card.strikeMessage(0);
        WizzmasCard.Card memory c = card.getCard(0);
        assertEq(c.message, 'Sender has a dirty kobold mouth xD');
    }

    function testStrikeMessageTokenNotMinted() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        wizards.mint();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();
        
        vm.expectRevert(bytes('Card not minted yet'));
        card.strikeMessage(1);
    }

    function testSenderCards() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        assertEq(card.getSenderCardIds(spz).length, 0);
        assertEq(card.getRecipientCardIds(jro).length, 0);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        wizards.mint();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();

        assertEq(card.getSenderCardIds(spz).length, 1);
        assertEq(card.getRecipientCardIds(jro).length, 1);


    }

    function testGetInvalidCard() public {
        vm.expectRevert(bytes("CARD_NOT_MINTED"));
        card.getCard(0);
    }

    function testMintCardForSupportedNFTs() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        wizards.mint();
        souls.mint();
        warriors.mint();
        ponies.mint();
        beasts.mint();
        spawn.mint();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        card.mint(address(souls), 0, 0, 0, validMessage, jro);
        card.mint(address(warriors), 0, 0, 0, validMessage, jro);
        card.mint(address(ponies), 0, 0, 0, validMessage, jro);
        card.mint(address(beasts), 0, 0, 0, validMessage, jro);
        card.mint(address(spawn), 0, 0, 0, validMessage, jro);
        vm.stopPrank();
    }

    function testMintCardWithUnsupportedNFT() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        artworkMinter.claim(0);
        DummyERC721 unsupp = new DummyERC721();
        unsupp.mint();

        vm.expectRevert();
        card.mint(address(unsupp), 0, 0, 0, validMessage, jro);
        vm.stopPrank();
    }

    function testMintCardWithInvalidMessageLength() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.prank(jro);
        wizards.mint();

        vm.startPrank(spz);
        artworkMinter.claim(0);
        vm.expectRevert();
        card.mint(address(wizards), 0, 0, 0, invalidMessage, jro);
        vm.stopPrank();
    }

    function testMintCardWithUnownedNFT() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.prank(jro);
        wizards.mint();
        vm.startPrank(spz);
        artworkMinter.claim(0);
        vm.expectRevert();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();
    }

    function testMintCardWithoutArtwork() public {
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        vm.startPrank(spz);
        wizards.mint();
        vm.expectRevert();
        card.mint(address(wizards), 0, 0, 0, validMessage, jro);
        vm.stopPrank();
    }
}
