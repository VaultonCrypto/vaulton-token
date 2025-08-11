// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../src/VaultonToken.sol";

contract TestVaulton is Vaulton {
    constructor(address router, address cexWallet) // FIX: Only 2 parameters
        Vaulton(router, cexWallet) // FIX: Only 2 arguments
    {}

    // Remplace la fonction interne pour les tests
    function _swapBNBForTokens(uint256 bnbAmount, uint256) internal pure returns (uint256) {
        // Simulate a successful swap: just return bnbAmount as tokens
        return bnbAmount;
    }

    // Pour les tests, on peut simuler le BNB reçu
    function simulateBNBReceived() external payable {
        // Cette fonction permet d'ajouter du BNB au contrat pour les tests
    }
    
    // Si tu veux vraiment une fonction pour définir un montant spécifique pour les tests
    function getBNBBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
