// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Marketplace} from "../src/ERCMarketplace.sol";
import {NFT} from "../src/NFT.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    IERC721Enumerable mockNFT;
    NFT nft;

    uint256 private userPrivateKey;
    uint256 private signerPrivateKey;

    uint256 tokenId;

    struct Order {
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool active;
    }

    function setUp() public {
        marketplace = new Marketplace();

        signerPrivateKey = vm.envUint("PK");
        userPrivateKey = vm.envUint("USER_PK");

        address signer = vm.addr(signerPrivateKey);

        // Deploy the NFT
        nft = new NFT("NFT_Marketplace", "MFT");
        tokenId = nft.mintTo(signer);
        // Prank user before approving the nft
        vm.prank(signer);
        nft.approve(address(marketplace), tokenId);
    }

    function constructSig(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        address _signer,
        uint256 _deadline
    ) public returns (bytes memory sig) {
        bytes32 mHash = keccak256(
            abi.encodePacked(
                _tokenAddress,
                _tokenId,
                _price,
                _signer,
                _deadline
            )
        );

        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, mHash);
        sig = getSig(v, r, s);
    }

    function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }

    // Create order with valid inputs
    function test_create_order_with_invalid_signature() public {
        // Create order with valid inputs
        address user = vm.addr(userPrivateKey);
        address signer = vm.addr(signerPrivateKey);
        // uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 3610;
        address tokenAddress = address(mockNFT);

        vm.startPrank(signer);

        bytes memory signature = constructSig(
            tokenAddress,
            tokenId,
            price,
            signer,
            deadline
        );
        vm.expectRevert("Invalid signature");

        marketplace.createOrder(
            tokenAddress,
            tokenId,
            price,
            signature,
            deadline
        );
    }

    // Create order with valid inputs
    function test_create_order_with_invalid_date() public {
        // Create order with valid inputs
        address user = vm.addr(userPrivateKey);
        address signer = vm.addr(signerPrivateKey);
        // uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 3600;
        address tokenAddress = address(mockNFT);

        vm.startPrank(signer);

        bytes memory signature = constructSig(
            tokenAddress,
            tokenId,
            price,
            signer,
            deadline
        );
        vm.expectRevert("Order cannot expire less than an hour");

        marketplace.createOrder(
            tokenAddress,
            tokenId,
            price,
            signature,
            deadline
        );
        vm.stopPrank();
    }

    function test_create_order_with_zero_price() public {
        address user = vm.addr(userPrivateKey);
        address signer = vm.addr(signerPrivateKey);
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 3600;
        address tokenAddress = address(mockNFT);
        uint256 orderId = 1;

        vm.startPrank(signer);

        bytes memory signature = constructSig(
            tokenAddress,
            tokenId,
            price,
            signer,
            deadline
        );

        // Create order with zero price
        marketplace.createOrder(tokenAddress, tokenId, 0, signature, deadline);

        // Assert that the order was not created
        Order memory order = marketplace.orders();
        // assert(order[orderId].active == false);
        vm.stopPrank();
    }

    function testFulfilOrder() public {}
}
