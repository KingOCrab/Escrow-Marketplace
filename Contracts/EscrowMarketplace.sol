// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MarketplaceEscrow {
    // Track the lifecycle of a product
    enum ItemState { Available, Locked, Released, Refunded }

    struct Item {
        string name;
        uint256 price;
        address payable seller;
        address payable buyer;
        ItemState state;
    }

    uint256 public itemCount = 0;
    mapping(uint256 => Item) public items;

    // 1. Seller lists a product
    function listItem(string memory _name, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero");
        itemCount++;
        items[itemCount] = Item({
            name: _name,
            price: _price,
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            state: ItemState.Available
        });
    }

    // 2. Buyer purchases the product (Funds held in contract escrow)
    function buyItem(uint256 _itemId) public payable {
        Item storage item = items[_itemId];
        require(item.state == ItemState.Available, "Item not available");
        require(msg.value == item.price, "Please submit the exact price");
        require(msg.sender != item.seller, "Seller cannot buy their own item");

        item.buyer = payable(msg.sender);
        item.state = ItemState.Locked; // Funds are now locked in the contract
    }

    // 3. Buyer confirms delivery (Contract releases funds to seller)
    function confirmDelivery(uint256 _itemId) public {
        Item storage item = items[_itemId];
        require(item.state == ItemState.Locked, "Item is not in escrow");
        require(msg.sender == item.buyer, "Only the buyer can confirm delivery");

        item.state = ItemState.Released;
        
        // Updated transfer method
        (bool success, ) = item.seller.call{value: item.price}("");
        require(success, "Transfer to seller failed");
    }

    // 4. Seller initiates refund (Contract returns funds to buyer)
    function refundBuyer(uint256 _itemId) public {
        Item storage item = items[_itemId];
        require(item.state == ItemState.Locked, "Item is not in escrow");
        require(msg.sender == item.seller, "Only the seller can authorize a refund");

        item.state = ItemState.Refunded;
        
        // Updated transfer method
        (bool success, ) = item.buyer.call{value: item.price}("");
        require(success, "Transfer to buyer failed");
    }
}