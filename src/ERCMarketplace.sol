// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    uint256 public ordersId = 0;

    struct Order {
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool active;
    }

    mapping(uint256 => Order) public orders;

    IERC721Enumerable public NFT;

    constructor() {}

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature,
        uint256 _deadline
    ) external {
        require(_deadline > block.timestamp, "Order deadline has passed");
        require(
            _deadline > block.timestamp + 3601,
            "Order cannot expire less than an hour"
        );
        require(_price > 0, "Price must be greater than zero");

        bytes32 orderHash = keccak256(
            abi.encodePacked(
                _tokenAddress,
                _tokenId,
                _price,
                msg.sender,
                _deadline
            )
        );

        require(
            recoverSigner(orderHash, _signature) == msg.sender,
            "Invalid signature"
        );

        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(
            token.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved to use token"
        );

        orders[ordersId] = Order(
            msg.sender,
            _tokenAddress,
            _tokenId,
            _price,
            _signature,
            _deadline,
            true
        );
        ordersId++;
    }

    function fulfillOrder(
        address _tokenAddress,
        uint256 _tokenId
    ) external payable {
        Order storage order = orders[_tokenId];
        require(order.active, "Order is not active");
        require(msg.value == order.price, "Incorrect payment amount");

        IERC721 token = IERC721(_tokenAddress);
        address seller = order.owner;

        payable(seller).transfer(msg.value);
        token.safeTransferFrom(seller, msg.sender, _tokenId);

        order.active = false;
    }

    function recoverSigner(
        bytes32 _message,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        require(_signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(_message, v, r, s);
    }
}
