// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Marketplace {
    // Create a counter of orders to know the previous order data.
    uint256 public ordersId = 0;
    uint256 public number;

    // Create a struct of orders to keep the orders data
    struct Order {
        address owner;
        address tokenId;
        uint256 price;
        bytes32 signature;
        uint256 deadline;
    }

    mapping(uint => Order) orders;

    function signOrder() internal {
        // (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        // emit log_address(alice);
        // bytes32 hash = keccak256("Signed by Alice");
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, hash);
        // address signer = ecrecover(hash, v, r, s);
        // assertEq(alice, signer); // [PASS]
    }

    function createOrder(
        address _tokenId,
        uint256 _price,
        uint256 _deadline
    ) public {
        /**
        tokenId -> The Id of the erc721 Token
        price -> The price of the erc721 Token
        deadline -> The deadline of the order.
            - 0 means block.timestamp
        */
        Order storage order = orders[ordersId];
        order.owner = msg.sender;
        order.tokenId = _tokenId;
        order.price = _price;
        if (ordersId > 0) {
            // Get the previous order info
            Order memory prevOrder = orders[ordersId];
            order.signature = keccak256(
                abi.encodePacked(
                    prevOrder.owner,
                    prevOrder.tokenId,
                    prevOrder.price,
                    prevOrder.signature,
                    prevOrder.deadline
                )
            );
        }
        order.deadline = block.timestamp + _deadline;
        ordersId++;
    }

    function fulfilOrder() public {}

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
