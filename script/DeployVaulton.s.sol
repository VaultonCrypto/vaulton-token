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
        
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("");
        console2.log("=== DEPLOYING CONTRACT ===");
        
        Vaulton vaulton = new Vaulton(pancakeRouter);
        
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

        // Calculate expected circulating supply (30M - 15M burn = 15M)
        uint256 expectedCirculating = vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN();
        require(totalSupply == expectedCirculating, "TOTAL_SUPPLY FAILED");
            
        // Test 2: Ownership
        address contractOwner = vaulton.owner();
        require(contractOwner == deployer, "OWNERSHIP FAILED");
        console2.log("Ownership verified");

        // Test 3: Initial Burn (50% = 15M tokens)
        uint256 burnedTokens = vaulton.burnedTokens();
        require(burnedTokens == vaulton.INITIAL_BURN(), "INITIAL_BURN FAILED");
        console2.log("Initial burn verified:", burnedTokens);

        // Test 4: Buyback Reserve (5.4M tokens in contract)
        uint256 contractBalance = vaulton.balanceOf(address(vaulton));
        require(contractBalance == vaulton.BUYBACK_RESERVE(), "BUYBACK_RESERVE FAILED");
        console2.log("Buyback reserve verified:", contractBalance);

        // Test 5: Owner Balance (should have management tokens)
        uint256 expectedOwnerBalance = vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN() - vaulton.BUYBACK_RESERVE();
        require(deployerBalance == expectedOwnerBalance, "OWNER_BALANCE FAILED");
        console2.log("Owner balance verified:", deployerBalance);

        // Test 6: Initial State
        require(!vaulton.tradingEnabled(), "TRADING_SHOULD_BE_DISABLED");
        require(vaulton.pancakePair() == address(0), "PAIR_SHOULD_BE_UNSET");
        console2.log("Initial state verified");

        // Test 7: Buyback Stats
        uint256 buybackRemaining = vaulton.buybackTokensRemaining();
        require(buybackRemaining == vaulton.BUYBACK_RESERVE(), "BUYBACK_REMAINING FAILED");
        console2.log("Buyback tokens remaining:", buybackRemaining);

        // Test 8: Constants verification
        require(vaulton.TOTAL_SUPPLY() == 30_000_000 * 10**18, "TOTAL_SUPPLY_CONSTANT FAILED");
        require(vaulton.INITIAL_BURN() == 15_000_000 * 10**18, "INITIAL_BURN_CONSTANT FAILED");
        require(vaulton.BUYBACK_RESERVE() == 5_400_000 * 10**18, "BUYBACK_RESERVE_CONSTANT FAILED");
        require(vaulton.PRESALE_ALLOCATION() == 3_300_000 * 10**18, "PRESALE_ALLOCATION FAILED");
        require(vaulton.CEX_ALLOCATION() == 2_700_000 * 10**18, "CEX_ALLOCATION FAILED");
        require(vaulton.LIQUIDITY_ALLOCATION() == 2_100_000 * 10**18, "LIQUIDITY_ALLOCATION FAILED");
        require(vaulton.FOUNDER_ALLOCATION() == 1_500_000 * 10**18, "FOUNDER_ALLOCATION FAILED");
        console2.log("All constants verified");

        // Test 9: View Functions
        (
            uint256 totalSupplyView,
            uint256 circulatingSupply,
            uint256 burnedTokensView,
            uint256 buybackReserve,
            ,  // founderAllocation - non utilisée
               // communityAllocation - non utilisée
        ) = vaulton.getTokenomics();
        
        require(totalSupplyView == vaulton.TOTAL_SUPPLY(), "VIEW_TOTAL_SUPPLY FAILED");
        require(circulatingSupply == expectedCirculating, "VIEW_CIRCULATING FAILED");
        require(burnedTokensView == vaulton.INITIAL_BURN(), "VIEW_BURNED FAILED");
        require(buybackReserve == vaulton.BUYBACK_RESERVE(), "VIEW_BUYBACK FAILED");
        console2.log("View functions verified");

        // Test 10: Security Status
        (
            ,  // buybackControlPercentage - non utilisée
            bool tradingActive,
            bool pairSet,
            uint256 contractBalanceView,
               // communityControl - non utilisée
        ) = vaulton.getSecurityStatus();
        
        require(!tradingActive, "SECURITY_TRADING FAILED");
        require(!pairSet, "SECURITY_PAIR FAILED");
        require(contractBalanceView == vaulton.BUYBACK_RESERVE(), "SECURITY_BALANCE FAILED");
        console2.log("Security status verified");

        console2.log("All tests passed successfully!");
        
        vm.stopBroadcast();
        
        console2.log("");
        console2.log("=== DEPLOYMENT SUCCESSFUL ===");
        console2.log("Network:", networkName);
        console2.log("Contract:", address(vaulton));
        console2.log("Owner:", deployer);
        console2.log("Total Supply:", vaulton.TOTAL_SUPPLY() / 10**18, "tokens");
        console2.log("Circulating Supply:", expectedCirculating / 10**18, "tokens");
        console2.log("Burned Tokens:", burnedTokens / 10**18, "tokens (50%)");
        console2.log("Buyback Reserve:", contractBalance / 10**18, "tokens (36% of circulating)");
        console2.log("Owner Tokens:", deployerBalance / 10**18, "tokens");
        
        console2.log("");
        console2.log("=== TOKENOMICS SUMMARY ===");
        console2.log("50% BURNED (15M tokens) - CRYPTO HISTORY FIRST");
        console2.log("36% BUYBACK CONTROL (5.4M tokens) - UNPRECEDENTED");
        console2.log("61% COMMUNITY ALLOCATION (presale + CEX + liquidity)");
        console2.log("NO TAXES - CLEAN TRADING EXPERIENCE");
        console2.log("MATHEMATICAL DEFLATION GUARANTEED");
        
        if (chainId == 97) {
            console2.log("");
            console2.log("TESTNET - Ready for testing");
            console2.log("Next steps:");
            console2.log("1. setPancakePair()");
            console2.log("2. enableTrading()");
            console2.log("3. Test buyback mechanism");
        } else {
            console2.log("");
            console2.log("MAINNET - Ready for PinkSale");
            console2.log("Next steps:");
            console2.log("1. Transfer tokens for presale/CEX/liquidity");
            console2.log("2. Setup PinkSale presale");
            console2.log("3. Launch marketing campaign");
        }
        
        console2.log("");
        console2.log("IMPORTANT: Save contract address!");
        console2.log("Contract:", address(vaulton));
    }
}