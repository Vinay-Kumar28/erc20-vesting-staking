// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev Custom ERC-20 Token with Ownable access control.
 * The contract mints an initial supply to the deployer.
 */
contract MyToken is ERC20, Ownable {
    
    /**
     * @dev Initializes the token with name and symbol, and mints initial supply to deployer.
     */
    constructor() 
        ERC20("Universe", "UNI")
        Ownable(msg.sender) // Set deployer as the contract owner
    {
        _mint(msg.sender, 1_000_000 * 10 ** decimals()); // Mint initial supply (adjust as needed)
    }

    function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}

}
