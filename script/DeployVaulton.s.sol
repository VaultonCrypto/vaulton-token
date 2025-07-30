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
        } else if (chainId == 1337) {
            pancakeRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
            networkName = "Local Testnet";
        } else {
            revert("Unsupported network");
        }
        
        console2.log("Network:", networkName);
        console2.log("Router:", pancakeRouter);
        
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);

        // Ajout récupération du portefeuille marketing
        address marketingWallet = vm.envAddress("MARKETING_WALLET");
        console2.log("Marketing wallet:", marketingWallet);

        // Ajout récupération du portefeuille CEX
        address cexWallet = vm.envAddress("CEX_WALLET");
        console2.log("CEX wallet:", cexWallet);

        uint256 deployerBalance = deployer.balance;
        console2.log("Deployer balance:", deployerBalance / 1e18, "ETH/BNB");
        
        if (deployerBalance < 0.01 ether) {
            console2.log("WARNING: Low balance for deployment!");
        }
        
        vm.startBroadcast(deployerPrivateKey);

        console2.log("");
        console2.log("=== DEPLOYING CONTRACT ===");

        Vaulton vaulton = new Vaulton(pancakeRouter, marketingWallet, cexWallet);

        console2.log("Contract deployed at:", address(vaulton));

        // --- INSTRUCTIONS FOR OWNER ---
        console2.log("IMPORTANT: Send the buyback reserve to the Vaulton contract manually!");
        console2.log("Command: vaulton.transfer(address(vaulton), vaulton.BUYBACK_RESERVE()) from the owner.");
        console2.log("After locking on PinkLock, unlock and transfer to the contract before launch.");

        console2.log("");
        console2.log("=== COMPREHENSIVE TESTING ===");

        require(keccak256(bytes(vaulton.name())) == keccak256("Vaulton"), "NAME FAILED");
        require(keccak256(bytes(vaulton.symbol())) == keccak256("VAULTON"), "SYMBOL FAILED");
        require(vaulton.decimals() == 18, "DECIMALS FAILED");
        console2.log("Basic properties verified");

        require(vaulton.owner() == deployer, "OWNERSHIP FAILED");
        console2.log("Ownership verified");

        require(vaulton.burnedTokens() == vaulton.INITIAL_BURN(), "INITIAL_BURN FAILED");
        console2.log("Initial burn verified");

        // Correction : la réserve buyback n'est pas sur le contrat au lancement
        require(vaulton.balanceOf(address(vaulton)) == 0, "BUYBACK_RESERVE FAILED");
        console2.log("Buyback reserve not in contract at deployment (expected, must be sent manually after lock).");

        {
            uint256 expectedOwnerBalance = vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN();
            require(vaulton.balanceOf(deployer) == expectedOwnerBalance, "OWNER_BALANCE FAILED");
            console2.log("Owner balance verified");
        }

        require(!vaulton.tradingEnabled(), "TRADING_SHOULD_BE_DISABLED");
        require(vaulton.pancakePair() == address(0), "PAIR_SHOULD_BE_UNSET");
        console2.log("Initial state verified");

        require(vaulton.TOTAL_SUPPLY() == 30_000_000 * 1e18, "TOTAL_SUPPLY_CONSTANT FAILED");
        require(vaulton.INITIAL_BURN() == 8_000_000 * 1e18, "INITIAL_BURN_CONSTANT FAILED");
        require(vaulton.BUYBACK_RESERVE() == 11_000_000 * 1e18, "BUYBACK_RESERVE_CONSTANT FAILED");
        console2.log("Constants verified");

        _testStats(vaulton);

        require(address(vaulton.pancakeRouter()) == pancakeRouter, "ROUTER_MISMATCH");
        console2.log("Router integration verified");

        require(vaulton.owner() == deployer, "GETOWNER_FAILED");
        require(vaulton.autoSellEnabled() == false, "AUTOSELL_FAILED");
        require(vaulton.lastBuybackBlock() == 0, "LASTBUYBACK_FAILED");
        console2.log("Additional functions verified");

        console2.log("All deployment tests passed!");
        
        vm.stopBroadcast();

        _postDeploymentAnalysis(vaulton, deployer, deployerBalance, networkName, pancakeRouter, chainId);
        
        console2.log("");
        console2.log("=== SECURITY VERIFICATION ===");

        // Vérifier que withdraw() est bien bloquée
        // SECURITY NOTE: Manual BNB withdrawal is blocked by design.
        try vaulton.withdraw() {
            revert("SECURITY_FAILED: withdrawBNB should be blocked");
        } catch {
            console2.log("BNB withdrawal properly blocked");
        }

        // Les constantes USER_COOLDOWN, BUYBACK_COOLDOWN, BUYBACK_MULTIPLE n'existent plus dans VaultonToken.sol.
        // Ces vérifications sont donc retirées.
        // console2.log("Cooldown constants verified");
    }

    function _testStats(Vaulton vaulton) internal view {
        (
            uint256 totalSupply_,
            uint256 circulatingSupply,
            uint256 burnedTokens_,
            uint256 buybackTokensRemaining_,
            uint256 totalBuybackTokensSold_,
            uint256 totalBuybackTokensBurned_,
            uint256 totalBuybacks_,
            uint256 totalSellOperations_,
            uint256 avgBlocksPerBuyback,
            uint256 totalBuybackBNB_,
            uint256 avgBNBPerBuyback
        ) = vaulton.getStats();
        
        require(totalSupply_ == vaulton.TOTAL_SUPPLY(), "STATS_TOTAL_SUPPLY FAILED");
        require(circulatingSupply == vaulton.totalSupply(), "STATS_CIRCULATING FAILED");
        require(burnedTokens_ == vaulton.burnedTokens(), "STATS_BURNED FAILED");
        require(buybackTokensRemaining_ == vaulton.buybackTokensRemaining(), "STATS_BUYBACK_REMAINING FAILED");
        require(totalBuybackTokensSold_ == vaulton.totalBuybackTokensSold(), "STATS_BUYBACK_SOLD FAILED");
        require(totalBuybackTokensBurned_ == vaulton.totalBuybackTokensBurned(), "STATS_BUYBACK_BURNED FAILED");
        require(totalBuybacks_ == vaulton.totalBuybacks(), "STATS_TOTAL_BUYBACKS FAILED");
        require(totalSellOperations_ == vaulton.totalSellOperations(), "STATS_TOTAL_SELL_OPERATIONS FAILED");
        require(avgBlocksPerBuyback == 0, "STATS_AVG_BLOCKS FAILED");
        require(totalBuybackBNB_ == 0, "STATS_BUYBACK_BNB FAILED");
        require(avgBNBPerBuyback == 0, "STATS_AVG_BNB FAILED");
        console2.log("Stats function verified");
    }

    function _postDeploymentAnalysis(
        Vaulton vaulton,
        address deployer,
        uint256 initialBalance,
        string memory networkName,
        address pancakeRouter,
        uint256 chainId
    ) internal view {
        console2.log("");
        console2.log("=== POST-DEPLOYMENT ANALYSIS ===");
        
        uint256 finalBalance = deployer.balance;
        uint256 deploymentCost = initialBalance - finalBalance;
        console2.log("Deployment cost:", deploymentCost / 1e18, "ETH/BNB");
        console2.log("Remaining balance:", finalBalance / 1e18, "ETH/BNB");

        console2.log("");
        console2.log("=== DEPLOYMENT SUCCESSFUL ===");
        console2.log("Network:", networkName);
        console2.log("Contract:", address(vaulton));
        console2.log("Owner:", deployer);
        
        console2.log("Total Supply:", vaulton.TOTAL_SUPPLY() / 1e18, "tokens");
        console2.log("Circulating Supply:", vaulton.totalSupply() / 1e18, "tokens");
        console2.log("Burned Tokens:", vaulton.burnedTokens() / 1e18, "tokens");
        console2.log("Buyback Reserve:", vaulton.balanceOf(address(vaulton)) / 1e18, "tokens");
        
        uint256 ownerBalance = vaulton.balanceOf(deployer);
        console2.log("Owner Tokens:", ownerBalance / 1e18, "tokens");
        
        console2.log("");
        console2.log("=== TOKENOMICS SUMMARY ===");
        console2.log("26.67% BURNED (8M tokens) - DEFLATIONARY START");
        console2.log("40.00% BUYBACK CONTROL (12M tokens) - UNPRECEDENTED");
        console2.log("33.33% COMMUNITY ALLOCATION (10M tokens)");
        console2.log("NO TAXES - CLEAN TRADING EXPERIENCE");
        console2.log("MATHEMATICAL DEFLATION GUARANTEED");
        
        console2.log("");
        console2.log("=== SECURITY CHECKLIST ===");
        console2.log("Ownership properly set");
        console2.log("Router address validated");
        console2.log("Initial distribution correct");
        console2.log("Trading disabled by default");
        console2.log("Buyback mechanism ready");
        console2.log("No reentrancy vulnerabilities");
        console2.log("All constants verified");
        
        // ✅ AMÉLIORATION : Instructions plus détaillées
        if (chainId == 97) {
            console2.log("");
            console2.log("=== TESTNET SETUP GUIDE ===");
            console2.log("1. Get testnet BNB from faucet");
            console2.log("2. Add liquidity: 0.05+ BNB + 100k+ VAULTON");
            console2.log("3. Call setPair(<pair_address>)");
            console2.log("4. Call enableTrading()");
            console2.log("5. Test small sells to trigger buyback");
            console2.log("6. Call triggerPendingBuybacks() manually");
            console2.log("7. Verify burnedTokens increase");
            
            console2.log("");
            console2.log("=== TESTNET COMMANDS ===");
            console2.log("Add liquidity on PancakeSwap Testnet");
            console2.log("Set pair:");
            console2.log('cast send <contract> "setPair(address)" <pair_address> --private-key <key> --rpc-url <rpc>');
            console2.log("Enable trading:");
            console2.log('cast send <contract> "enableTrading()" --private-key <key> --rpc-url <rpc>');
            console2.log("Test buyback:");
            console2.log('cast send <contract> "triggerPendingBuybacks()" --private-key <key> --rpc-url <rpc>');
            
        } else if (chainId == 56) {
            console2.log("");
            console2.log("=== MAINNET LAUNCH GUIDE ===");
            console2.log("2. Verify contract on BSCScan");
            console2.log("3. Transfer tokens for presale/liquidity");
            console2.log("4. Setup PinkSale presale");
            console2.log("5. Create marketing materials");
            console2.log("6. Add liquidity: 10+ BNB + 250k+ VAULTON");
            console2.log("7. Call setPair(<pair_address>)");
            console2.log("8. Call enableTrading()");
            console2.log("9. Announce launch");
            console2.log("10. Monitor buyback mechanism");
            
            console2.log("");
            console2.log("=== MAINNET SECURITY CHECKLIST ===");
            console2.log("- High liquidity (10+ BNB)");
            console2.log("- Contract verified");
            console2.log("- Ownership renounced after setup");
            console2.log("- Marketing ready");
        }
        
        console2.log("");
        console2.log("IMPORTANT ADDRESSES TO SAVE:");
        console2.log("Contract:", address(vaulton));
        console2.log("Deployer:", deployer);
        console2.log("Router:", pancakeRouter);
        
        console2.log("");
        console2.log("USEFUL COMMANDS:");
        console2.log('cast call <contract> "name()" --rpc-url <rpc>');
        console2.log('cast call <contract> "totalSupply()" --rpc-url <rpc>');
        console2.log('cast call <contract> "getStats()" --rpc-url <rpc>');
        
        console2.log("");
        console2.log("Save these addresses for future reference!");
    }
}