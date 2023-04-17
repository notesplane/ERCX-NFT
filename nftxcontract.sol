pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC_X is ERC721, IERC721Enumerable, IERC1155 {
    // Dynamic Properties and Events
    struct DynamicProperty {
        bytes32 propertyKey;
        string value;
        uint256 lastUpdated;
    }

    mapping(uint256 => DynamicProperty[]) public dynamicProperties;
    event PropertyChanged(uint256 indexed tokenId, bytes32 indexed propertyKey, string newValue, uint256 updatedAt);

    // Royalty
    uint256 public constant royaltyPercentage = 10;
    event RoyaltyReceived(address indexed creator, uint256 amount);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
    }

    // ERC-X specific functions

    function setDynamicProperty(uint256 tokenId, bytes32 propertyKey, string memory newValue) public {
        require(_exists(tokenId), "ERC-X: non-existent token");
        require(msg.sender == ownerOf(tokenId), "ERC-X: only token owner can modify properties");

        DynamicProperty[] storage properties = dynamicProperties[tokenId];
        uint256 index = _findPropertyIndex(properties, propertyKey);

        if (index == properties.length) {
            properties.push(DynamicProperty(propertyKey, newValue, block.timestamp));
        } else {
            properties[index].value = newValue;
            properties[index].lastUpdated = block.timestamp;
        }

        emit PropertyChanged(tokenId, propertyKey, newValue, block.timestamp);
    }

    function _findPropertyIndex(DynamicProperty[] storage properties, bytes32 propertyKey) internal view returns (uint256) {
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].propertyKey == propertyKey) {
                return i;
            }
        }

        return properties.length;
    }

    // Royalty Handling

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0)) {
            uint256 royaltyAmount = _calculateRoyaltyAmount(tokenId);
            _sendRoyaltyToCreator(from, tokenId, royaltyAmount);
        }
    }

    function _calculateRoyaltyAmount(uint256 tokenId) internal view returns (uint256) {
        uint256 tokenValue = 1 ether; // Replace this with a function to fetch token value
        return (tokenValue * royaltyPercentage) / 100;
    }

    function _sendRoyaltyToCreator(address from, uint256 tokenId, uint256 royaltyAmount) internal {
        address creator = ownerOf(tokenId);
        (bool success, ) = creator.call{value: royaltyAmount}("");
        require(success, "ERC-X: Failed to send royalty");

        emit RoyaltyReceived(creator, royaltyAmount);
    }
}
