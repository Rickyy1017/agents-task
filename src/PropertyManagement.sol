// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PropertyManagement is AccessControl {

    IERC20 public paymentToken;

    bytes32 public constant PROPERTY_MANAGER_ROLE =
        keccak256("PROPERTY_MANAGER_ROLE");

    uint256 public propertyCounter;

    struct Property {
        uint256 id;
        string name;
        string location;
        uint256 price;
        address owner;
        bool isForSale;
    }

    mapping(uint256 => Property) public properties;
    uint256[] private propertyIds;

    event PropertyCreated(uint256 indexed id, string name, uint256 price);
    event PropertyRemoved(uint256 indexed id);
    event PropertyPurchased(uint256 indexed id, address buyer);

    constructor(address _tokenAddress) {
        paymentToken = IERC20(_tokenAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROPERTY_MANAGER_ROLE, msg.sender);
    }

    // create

    function createProperty(
        string memory _name,
        string memory _location,
        uint256 _price
    ) external onlyRole(PROPERTY_MANAGER_ROLE) {

        require(_price > 0, "Invalid price");

        propertyCounter++;

        properties[propertyCounter] = Property({
            id: propertyCounter,
            name: _name,
            location: _location,
            price: _price,
            owner: address(this),
            isForSale: true
        });

        propertyIds.push(propertyCounter);

        emit PropertyCreated(propertyCounter, _name, _price);
    }

    // delete

    function removeProperty(uint256 _id)
        external
        onlyRole(PROPERTY_MANAGER_ROLE)
    {
        require(properties[_id].id != 0, "Does not exist");

        delete properties[_id];

        emit PropertyRemoved(_id);
    }

    //get

    function getAllProperties()
        external
        view
        returns (Property[] memory)
    {
        Property[] memory all =
            new Property[](propertyIds.length);

        for (uint256 i = 0; i < propertyIds.length; i++) {
            all[i] = properties[propertyIds[i]];
        }

        return all;
    }

    // buy

    function buyProperty(uint256 _id) external {

        Property storage property = properties[_id];

        require(property.id != 0, "Does not exist");
        require(property.isForSale, "Not for sale");

        bool success = paymentToken.transferFrom(
            msg.sender,
            property.owner,
            property.price
        );

        require(success, "Payment failed");

        property.owner = msg.sender;
        property.isForSale = false;

        emit PropertyPurchased(_id, msg.sender);
    }

 
    function setForSale(uint256 _id, uint256 _price) external {

        Property storage property = properties[_id];

        require(property.owner == msg.sender, "Not owner");
        require(_price > 0, "Invalid price");

        property.price = _price;
        property.isForSale = true;
    }
}
