// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWETH is ERC20 {
    // Store contract balance
    uint256 private _totalSupply;

    constructor() ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    // External mint when receiving ETH
    receive() external payable {
        _mint(msg.sender, msg.value);
        _totalSupply += msg.value;
    }

    // External mint function
    function deposit() external payable {
        _mint(msg.sender, msg.value);
        _totalSupply += msg.value;
    }

    // External burn function
    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        _totalSupply -= amount;
        payable(msg.sender).transfer(amount);
    }
}