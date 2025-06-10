// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/VaultonToken.sol";

contract DeployVaulton is Script {
    
    function run() external {
        console2.log("=== Deploying Vaulton Token ===");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        
        address pancakeRouter;
        string memory networkName;
        
        if (chainId == 97) {
            pancakeRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
            networkName = "BSC Testnet";
        } else if (chainId == 56) {
            pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
            networkName = "BSC Mainnet";
        } else {
            revert("Unsupported network");
        }
        
        console2.log("Network:", networkName);
        console2.log("Router:", pancakeRouter);
        
        address marketingWallet = vm.envAddress("MARKETING_WALLET");
        address cexWallet = vm.envAddress("CEX_WALLET");
        address operationsWallet = vm.envAddress("OPERATIONS_WALLET");
        
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);
        console2.log("Marketing Wallet:", marketingWallet);
        console2.log("CEX Wallet:", cexWallet);
        console2.log("Operations Wallet:", operationsWallet);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("");
        console2.log("=== DEPLOYING CONTRACT ===");
        
        Vaulton vaulton = new Vaulton(
            pancakeRouter,
            marketingWallet,
            cexWallet,
            operationsWallet
        );
        
        console2.log("Contract deployed at:", address(vaulton));
        
        console2.log("");
        console2.log("=== COMPREHENSIVE TESTING ===");

        // Test 1: Basic Properties
        string memory tokenName = vaulton.name();
        string memory tokenSymbol = vaulton.symbol();
        uint8 decimals = vaulton.decimals();
        uint256 totalSupply = vaulton.totalSupply();
        uint256 deployerBalance = vaulton.balanceOf(deployer);

        console2.log("Name:", tokenName);
        console2.log("Symbol:", tokenSymbol);
        console2.log("Decimals:", decimals);
        console2.log("Total Supply (Circulating):", totalSupply);
        console2.log("Deployer Balance:", deployerBalance);

        require(keccak256(bytes(tokenName)) == keccak256(bytes("Vaulton")), "NAME FAILED");
        require(keccak256(bytes(tokenSymbol)) == keccak256(bytes("VAULTON")), "SYMBOL FAILED");
        require(decimals == 18, "DECIMALS FAILED");

        // Calculate expected circulating supply
        uint256 expectedCirculating = vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN();
        require(totalSupply == expectedCirculating, "TOTAL_SUPPLY FAILED");
            
        // Test 2: Ownership
        address contractOwner = vaulton.owner();
        require(contractOwner == deployer, "OWNERSHIP FAILED");
        console2.log("Ownership verified");

        // Test 3: Initial Burn
        require(deployerBalance == expectedCirculating, "INITIAL_BURN FAILED");
        console2.log("Initial burn verified:", vaulton.INITIAL_BURN());

        // Test 4: Wallet Addresses
        require(vaulton.marketingWallet() == marketingWallet, "MARKETING_WALLET FAILED");
        require(vaulton.cexWallet() == cexWallet, "CEX_WALLET FAILED");
        require(vaulton.operationsWallet() == operationsWallet, "OPERATIONS_WALLET FAILED");
        console2.log("All wallets verified");

        // Test 5: Initial State
        require(!vaulton.tradingEnabled(), "TRADING_SHOULD_BE_DISABLED");
        require(!vaulton.taxesRemoved(), "TAXES_SHOULD_BE_ACTIVE");
        console2.log("Initial state verified");

        // Test 6: Burn State
        uint256 burnedTokens = vaulton.burnedTokens();
        console2.log("Burned tokens:", burnedTokens);
        require(burnedTokens == vaulton.INITIAL_BURN(), "BURN_STATE_FAILED");

        // Test 7: Marketing State
        uint256 marketingTokens = vaulton.marketingTokensAccumulated();
        console2.log("Marketing tokens:", marketingTokens);
        require(marketingTokens == 0, "MARKETING_STATE_FAILED");

        console2.log("All tests passed successfully!");
        
        vm.stopBroadcast();
        
        console2.log("");
        console2.log("=== DEPLOYMENT SUCCESSFUL ===");
        console2.log("Network:", networkName);
        console2.log("Contract:", address(vaulton));
        console2.log("Owner:", deployer);
        console2.log("Circulating Supply:", deployerBalance);
        
        if (chainId == 97) {
            console2.log("TESTNET - Ready for testing");
        } else {
            console2.log("MAINNET - Ready for PinkSale");
        }
        
        console2.log("IMPORTANT: Save contract address!");
    }
}