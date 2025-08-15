// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../src/VaultonToken.sol";

contract TestVaulton is Vaulton {
    constructor(address router, address cexWallet) // FIX: Only 2 parameters
        Vaulton(router, cexWallet) // FIX: Only 2 arguments
    {}

    // Override the internal function for testing
    function _swapBNBForTokens(uint256 bnbAmount, uint256) internal pure returns (uint256) {
        // Simulate a successful swap: just return bnbAmount as tokens
        return bnbAmount;
    }

    // For testing, you can simulate BNB received
    function simulateBNBReceived() external payable {
        // This function allows adding BNB to the contract for testing
    }
    
    // If you really want a function to set a specific amount for tests
    function getBNBBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
