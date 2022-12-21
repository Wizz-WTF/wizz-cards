// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/utils/LibString.sol";
import "../../src/WizzWTF.sol";
import "../../src/WizzWTFMinter.sol";
import "../../src/WizzmasCard.sol";

contract WizzmasScript is Script {
    function run() external {

        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address owner = vm.envAddress("OWNER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Artworks
        uint256 numArtworkTypes = 1;
        WizzWTF artwork = new WizzWTF(deployer);
        for (uint i = 0; i < numArtworkTypes; i++) {
            artwork.setTokenURI(
                i,
                string.concat(
                    vm.envString("BASE_URI_ARTWORKS"),
                    LibString.toString(i)
                )
            );
        }

        // Artworks Minter
        WizzWTFMinter artworkMinter = new WizzWTFMinter(
            address(artwork),
            numArtworkTypes,
            deployer
        );
        artwork.addMinter(address(artworkMinter));

        // Cards
        uint8 numTemplateTypes = 3;
        address[] memory supportedTokens = new address[](3);
        supportedTokens[0] = vm.envAddress("CONTRACT_ADDRESS_WIZARDS");
        supportedTokens[1] = vm.envAddress("CONTRACT_ADDRESS_SOULS");
        supportedTokens[2] = vm.envAddress("CONTRACT_ADDRESS_WARRIORS");

        WizzmasCard card = new WizzmasCard(
            address(artwork),
            supportedTokens,
            numTemplateTypes,
            vm.envString("BASE_URI_CARDS"),
            deployer
        );

        // set mintEnabled
        artworkMinter.setMintEnabled(true);
        card.setMintEnabled(true);

        // transfer ownership
        artwork.transferOwnership(owner);
        artworkMinter.transferOwnership(owner);
        card.transferOwnership(owner);

        vm.stopBroadcast();
    }
}
