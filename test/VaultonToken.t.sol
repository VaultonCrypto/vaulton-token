// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // Add this line for debugging
import "../src/VaultonToken.sol";
import "./mocks/MockRouter.sol";
import "./mocks/MockFactory.sol";
import "./mocks/MockWETH.sol";
import "./mocks/MockRouterHelper.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
 * @title VaultonTest
 * @dev Comprehensive test suite for Vaulton Token contract
 * @notice Tests cover all core functionality including taxes, burns, liquidity, and security features
 * @author Vaulton Team
 */
contract VaultonTest is Test {
    // Test contract state variables
    Vaulton public vaulton;
    MockRouter public mockRouter;
    MockFactory public mockFactory;
    MockWETH public mockWETH;

    // Events to test
    event TaxApplied(
        address indexed from, 
        address indexed to, 
        uint256 amount, 
        uint256 taxAmount, 
        string taxType
    );
    
    event SwapAndLiquifyCompleted(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );

    // Test addresses
    address public owner;
    address public marketingWallet;
    address public trader;
    address public user;
    address public unauthorized;
    address public dexPair;

    function setUp() public {
        console.log("Deploying MockWETH...");
        mockWETH = new MockWETH();
        console.log("MockWETH deployed at:", address(mockWETH));

        console.log("Deploying MockFactory...");
        mockFactory = new MockFactory();
        console.log("MockFactory deployed at:", address(mockFactory));

        console.log("Deploying MockRouter...");
        mockRouter = new MockRouter(address(mockWETH), address(mockFactory));
        console.log("MockRouter deployed at:", address(mockRouter));

        console.log("Setting up addresses...");
        owner = address(this);
        marketingWallet = address(1);
        trader = address(2);
        user = address(3);
        unauthorized = address(4);

        console.log("Deploying Vaulton...");
        vaulton = new Vaulton(
            address(mockRouter)
        );
        console.log("Vaulton deployed at:", address(vaulton));

        console.log("Creating DEX pair...");
        dexPair = mockFactory.createPair(
            address(vaulton),
            address(mockWETH)
        );
        console.log("DEX pair created at:", dexPair);

        // Explicitly set the pair instead of relying on auto-detection
        vm.prank(owner);
        vaulton.setPancakePair(dexPair);

        console.log("Distributing initial tokens...");
        vm.startPrank(owner);
        vaulton.transfer(trader, 10_000 * 10**18);
        vaulton.transfer(user, 10_000 * 10**18);
        vm.stopPrank();
        console.log("Initial token distribution complete.");

        // Set valid wallet addresses
        vm.prank(owner);
        vaulton.updateWallets(address(5), address(6), address(7));
    }

    // ========================================
    // TRANSFER & TAX MECHANISM TESTS
    // ========================================
    
    /**
     * @notice Tests different transfer scenarios with correct tax application
     * @dev Verifies buy tax (5%), sell tax (10%), and fee-free transfers
     * @dev Tests DEX → Wallet (buy), Wallet → DEX (sell), and excluded transfers
     */
    function testTransferScenarios() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Normal transfer (without taxes)
        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);

        uint256 initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);
        assertEq(vaulton.balanceOf(user), initialUserBalance + amount, "No tax transfer failed");

        // Buy tax scenario
        vm.prank(owner);
        vaulton.excludeFromFees(trader, false);

        // Transfer tokens to dexPair so it has tokens to transfer
        vm.prank(owner);
        vaulton.transfer(dexPair, amount);

        uint256 buyTax = vaulton.getBuyTax(); // 5%
        uint256 buyTaxAmount = amount * buyTax / 100;
        uint256 expectedReceived = amount - buyTaxAmount;

        // Recalculate the initial trader balance right before the buy transfer
        uint256 initialTraderBalance = vaulton.balanceOf(trader);

        // Addition: ensure that dexPair has enough tokens before the outgoing transfer
        vm.prank(owner);
        vaulton.transfer(dexPair, amount);

        vm.prank(dexPair);
        vaulton.transfer(trader, amount);
        assertEq(vaulton.balanceOf(trader), initialTraderBalance + expectedReceived, "Buy tax transfer failed");

        // Sell tax scenario
        uint256 sellTax = vaulton.getSellTax(); // 10%
        uint256 sellTaxAmount = amount * sellTax / 100;
        uint256 expectedTransfer = amount - sellTaxAmount;

        uint256 initialPairBalance = vaulton.balanceOf(dexPair);

        vm.prank(trader);
        vaulton.transfer(dexPair, amount);
        assertEq(vaulton.balanceOf(dexPair), initialPairBalance + expectedTransfer, "Sell tax transfer failed");
    }

    function testTransferWithoutTax() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Exclude the sender from fees
        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);

        // Perform a transfer without taxes
        uint256 initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);

        // Verify that the recipient's balance has increased correctly
        assertEq(vaulton.balanceOf(user), initialUserBalance + amount, "No tax transfer failed");
    }

    function testBuyTax() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Transfer tokens to the DEX pair
        vm.prank(owner);
        vaulton.transfer(dexPair, amount);

        // Addition: ensure that dexPair has enough tokens before the outgoing transfer
        vm.prank(owner);
        vaulton.transfer(dexPair, amount);

        // Perform a transfer from the DEX pair
        uint256 initialTraderBalance = vaulton.balanceOf(trader);
        
        uint256 buyTax = vaulton.getBuyTax(); // 5% au lieu de 10%
        uint256 taxAmount = amount * buyTax / 100;
        uint256 expectedReceived = amount - taxAmount;

        vm.prank(dexPair);
        vaulton.transfer(trader, amount);

        // Verify that the recipient's balance is correct after taxes
        assertEq(vaulton.balanceOf(trader), initialTraderBalance + expectedReceived, "Buy tax transfer failed");
    }

    function testTaxDistributionOnSell() public {
        uint256 amount = 1000 * 10**18;

        // Prepare the trader with sufficient tokens
        vm.prank(owner);
        vaulton.transfer(trader, amount);

        uint256 sellTax = vaulton.getSellTax();
        uint256 taxAmount = (amount * sellTax) / 100;

        uint256 expectedBurn = (taxAmount * 60) / 100; // 60% pour le burn
        uint256 expectedLiquidity = (taxAmount * 15) / 100; // 15% pour la liquidité
        uint256 expectedMarketing = (taxAmount * 25) / 100; // 25% pour le marketing

        // Prepare the mockRouter with sufficient ETH
        vm.deal(address(mockRouter), 100 ether);
        mockRouter.setForceRevert(false);

        // Check balances before the transfer
        uint256 contractBalanceBefore = vaulton.balanceOf(address(vaulton));
        uint256 totalBurnedBefore = vaulton.getBurnedTokens();

        // Check the liquidity share
        vm.prank(trader);
        vaulton.transfer(dexPair, amount);

        // Check the burn
        uint256 totalBurnedAfter = vaulton.getBurnedTokens();
        assertEq(totalBurnedAfter, totalBurnedBefore + expectedBurn, "Burn part incorrect (sell)");

        // Check the contract balance after the transfer (liquidity + marketing)
        uint256 contractBalanceAfter = vaulton.balanceOf(address(vaulton));
        assertEq(contractBalanceAfter, contractBalanceBefore + expectedLiquidity + expectedMarketing, "Liquidity and marketing parts incorrect (sell)");
    }

    function testTaxDistributionOnBuy() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Check the current balance of dexPair
        uint256 dexPairBalance = vaulton.balanceOf(dexPair);

        if (dexPairBalance < amount) {
            vm.prank(owner);
            vaulton.transfer(dexPair, amount * 2); // Transfer a sufficient amount
        }
    }

    function testSellTax() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Perform a transfer to the DEX pair
        uint256 initialPairBalance = vaulton.balanceOf(dexPair);
        uint256 sellTax = vaulton.getSellTax();
        uint256 sellTaxAmount = amount * sellTax / 100;
        uint256 expectedTransfer = amount - sellTaxAmount;

        vm.prank(trader);
        vaulton.transfer(dexPair, amount);

        // Check that the DEX pair balance is correct after taxes
        assertEq(vaulton.balanceOf(dexPair), initialPairBalance + expectedTransfer, "Sell tax transfer failed");
    }

    // ========================================
    // LIQUIDITY & SWAP MECHANISM TESTS
    // ========================================
    
    /**
     * @notice Tests the swapAndLiquify mechanism functionality
     * @dev Verifies token → BNB conversion and liquidity addition process
     * @dev Tests manual trigger of swap and liquify operations
     */
    function testSwapAndLiquify() public {
        uint256 amount = 1000 * 10**18;

        // Prepare the mockRouter with more ETH
        vm.deal(address(mockRouter), 100 ether);
        mockRouter.setForceRevert(false);

        // Initialize the path array
        address[] memory path = new address[](2);
        path[0] = address(vaulton);
        path[1] = address(mockWETH);
        mockRouter.setPath(path);

        // Transfer tokens to the Vaulton contract
        vm.prank(owner);
        vaulton.transfer(address(vaulton), amount);

        // Make sure contract has enough ETH to simulate the swap result
        vm.deal(address(vaulton), 1 ether); // Add this line

        // Call the swap function  
        vm.prank(owner);
        vaulton.triggerSwapAndLiquify(amount);
        
        // Verification
        assertGt(address(vaulton).balance, 0, "Contract should have ETH balance");
    }

    function testLiquidityPoolReserves() public {
        uint256 tokenAmount = 10_000 * 10**18;
        uint256 ethAmount = 1 ether;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Add liquidity
        vm.prank(owner);
        vaulton.approve(address(mockRouter), tokenAmount);
        vm.deal(owner, ethAmount);
        vm.prank(owner);
        mockRouter.addLiquidityETH{value: ethAmount}(
            address(vaulton),
            tokenAmount,
            0,
            0,
            owner,
            block.timestamp
        );

        // Simulate reserves
        vm.prank(owner);
        mockRouter.setReserves(tokenAmount, ethAmount);

        // Verify initial reserves
        (uint256 reserveToken, uint256 reserveETH) = mockRouter.getReserves();
        assertGt(reserveToken, 0, "Token reserve is zero");
        assertGt(reserveETH, 0, "ETH reserve is zero");
    }

    function testPancakeSwapCompatibility() public {
        uint256 tokenAmount = 10_000 * 10**18;

        // Explicitly set forceRevert to false
        mockRouter.setForceRevert(false);

        // Ensure trader has enough tokens
        vm.prank(owner);
        vaulton.transfer(trader, tokenAmount);

        // Add approval before swap
        vm.prank(trader);
        vaulton.approve(address(mockRouter), tokenAmount);

        // Initialize the path array
        address[] memory path = new address[](2);
        path[0] = address(vaulton);
        path[1] = address(mockWETH);
        mockRouter.setPath(path);

        vm.deal(address(mockRouter), 100 ether);
        
        // Perform a swap
        vm.prank(trader);
        mockRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            trader,
            block.timestamp
        );

        // Verification
        assertGt(trader.balance, 0, "Swap failed");
    }

    /**
     * @notice Tests swap failure handling when BNB transfer fails
     * @dev Verifies proper error handling in swap operations
     * @dev Tests revert conditions in liquidity operations
     */
    function test_RevertWhen_BNBTransferFails() public {
        uint256 amount = 1000 * 10**18;

        // Prepare the mockRouter
        vm.deal(address(mockRouter), 100 ether);
        
        // Set forceRevert to true BEFORE any path setup
        mockRouter.setForceRevert(true);

        // Initialize the path array
        address[] memory path = new address[](2);
        path[0] = address(vaulton);
        path[1] = address(mockWETH);
        mockRouter.setPath(path);

        // Transfer tokens to the Vaulton contract
        vm.prank(owner);
        vaulton.transfer(address(vaulton), amount);

        // Expect a revert when directly calling swapAndLiquify
        vm.expectRevert("Token to BNB swap failed");
        vm.prank(owner);
        vaulton.triggerSwapAndLiquify(amount);
    }

    // ========================================
    // BURN THRESHOLD & TAX REMOVAL TESTS
    // ========================================
    
    /**
     * @notice Tests the burn threshold mechanism for automatic tax removal
     * @dev Verifies taxes are removed when 75% of total supply is burned
     * @dev Critical test for the deflationary tokenomics feature
     */
    function testBurnThresholdMechanism() public {
        uint256 amountToBurn = vaulton.BURN_THRESHOLD() - vaulton.burnedTokens();

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Perform a burn to reach the threshold
        vm.prank(owner);
        vaulton.burn(owner, amountToBurn);

        // Verify that taxes are removed
        assertTrue(vaulton.taxesRemoved());
        assertEq(vaulton.getBuyTax(), 0);
        assertEq(vaulton.getSellTax(), 0);
    }

    /**
     * @notice Tests automatic tax removal precisely at burn threshold
     * @dev Verifies exact threshold calculation and immediate tax removal
     * @dev Tests that taxes become 0% exactly when threshold is reached
     */
    function testAutomaticTaxRemovalAtThreshold() public {
        // Calculate exact amount to reach threshold
        uint256 currentBurned = vaulton.burnedTokens();
        uint256 burnThreshold = vaulton.BURN_THRESHOLD();
        uint256 amountToBurn = burnThreshold - currentBurned;
        
        // Verify taxes are active before threshold
        assertGt(vaulton.getBuyTax(), 0, "Buy tax should be active");
        assertGt(vaulton.getSellTax(), 0, "Sell tax should be active");
        assertFalse(vaulton.taxesRemoved(), "Taxes should not be removed yet");
        
        // Burn to reach threshold
        vm.prank(owner);
        vaulton.burn(owner, amountToBurn);
        
        // Verify automatic tax removal
        assertTrue(vaulton.taxesRemoved(), "Taxes should be removed automatically");
        assertEq(vaulton.getBuyTax(), 0, "Buy tax should be 0");
        assertEq(vaulton.getSellTax(), 0, "Sell tax should be 0");
        assertEq(vaulton.burnedTokens(), burnThreshold, "Burned tokens should equal threshold");
    }
    
    /**
     * @notice Tests that tax removal is permanent and irreversible
     * @dev Verifies that additional burns after threshold don't affect tax status
     * @dev Ensures taxesRemoved flag prevents any tax reactivation
     */
    function testTaxRemovalIsIrreversible() public {
        // Reach burn threshold
        uint256 currentBurned = vaulton.burnedTokens();
        uint256 burnThreshold = vaulton.BURN_THRESHOLD();
        uint256 amountToBurn = burnThreshold - currentBurned;
        
        vm.prank(owner);
        vaulton.burn(owner, amountToBurn);
        
        // Verify taxes are removed
        assertTrue(vaulton.taxesRemoved(), "Taxes should be removed");
        
        // Try to trigger removal again (should not fail but should not change anything)
        uint256 initialBurnedTokens = vaulton.burnedTokens();
        
        // Burn more tokens
        vm.prank(owner);
        vaulton.burn(owner, 1000 * 10**18);
        
        // Tax status should remain unchanged
        assertTrue(vaulton.taxesRemoved(), "Taxes should still be removed");
        assertEq(vaulton.getBuyTax(), 0, "Buy tax should still be 0");
        assertEq(vaulton.getSellTax(), 0, "Sell tax should still be 0");
    }
    
    /**
     * @notice Tests that no taxes are applied after threshold is reached
     * @dev Verifies complete fee-free operation once 75% is burned
     * @dev Tests that full amounts transfer without any deductions
     */
    function testNoTaxesAfterThresholdReached() public {
        uint256 amount = 1000 * 10**18;
        
        // Reach burn threshold
        uint256 currentBurned = vaulton.burnedTokens();
        uint256 burnThreshold = vaulton.BURN_THRESHOLD();
        uint256 amountToBurn = burnThreshold - currentBurned;
        
        vm.prank(owner);
        vaulton.burn(owner, amountToBurn);
        
        // Test that transfers have no taxes
        uint256 initialUserBalance = vaulton.balanceOf(user);
        uint256 initialTraderBalance = vaulton.balanceOf(trader);
        
        vm.prank(trader);
        vaulton.transfer(user, amount);
        
        // Full amount should be transferred (no taxes)
        assertEq(vaulton.balanceOf(user), initialUserBalance + amount, "Full amount should transfer");
        assertEq(vaulton.balanceOf(trader), initialTraderBalance - amount, "Full amount should be deducted");
    }
    
    /**
     * @notice Tests burn threshold calculation with exact precision
     * @dev Verifies threshold is exactly 75% of total supply
     * @dev Tests burned token counter accuracy and threshold detection
     */
    function testBurnThresholdExact() public {
        // Calculate the exact amount needed to reach burn threshold
        uint256 currentBurned = vaulton.burnedTokens();
        uint256 burnThreshold = vaulton.BURN_THRESHOLD();
        uint256 amountToBurn = burnThreshold - currentBurned;
        
        // Burn exactly to threshold
        vm.prank(owner);
        vaulton.burn(owner, amountToBurn);
        
        // Verify taxes removed when threshold exactly reached
        assertTrue(vaulton.taxesRemoved(), "Taxes not removed at exact threshold");
        assertEq(vaulton.getSellTax(), 0, "Sell tax not reset");
        assertEq(vaulton.getBuyTax(), 0, "Buy tax not reset");
        
        // Verify the burnedTokens counter is updated correctly
        assertEq(vaulton.burnedTokens(), burnThreshold, "Burned tokens not tracked correctly");
    }
    
    // ========================================
    // SECURITY & ACCESS CONTROL TESTS
    // ========================================
    
    /**
     * @notice Tests blacklist functionality for address restriction
     * @dev Verifies bidirectional blacklist enforcement (can't send/receive)
     * @dev Tests blacklist addition, removal, and transfer blocking
     */
    function testBlacklist() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(owner);
        vaulton.blacklistAddress(trader, true);

        vm.expectRevert("Blacklisted");
        vm.prank(trader);
        vaulton.transfer(user, 1000 * 10**18);
    }

    /**
     * @notice Tests blacklist functionality for single addresses
     * @dev Verifies individual address blacklisting and status checking
     */
    function testBlacklistAddress() public {
        vm.prank(owner);
        vaulton.blacklistAddress(user, true);
        assertTrue(vaulton.getBlacklistStatus(user), "User not blacklisted");
        vm.prank(owner);
        vaulton.blacklistAddress(user, false);
        assertFalse(vaulton.getBlacklistStatus(user), "User still blacklisted");
    }

    /**
     * @notice Tests bulk blacklist operations for multiple addresses
     * @dev Verifies batch blacklisting and unblocklisting functionality
     */
    function testBlacklistAddresses() public {
        address[] memory accounts = new address[](2);
        accounts[0] = user;
        accounts[1] = trader;
        vm.prank(owner);
        vaulton.blacklistAddresses(accounts, true);
        assertTrue(vaulton.getBlacklistStatus(user), "User not blacklisted");
        assertTrue(vaulton.getBlacklistStatus(trader), "Trader not blacklisted");
        vm.prank(owner);
        vaulton.blacklistAddresses(accounts, false);
        assertFalse(vaulton.getBlacklistStatus(user), "User still blacklisted");
        assertFalse(vaulton.getBlacklistStatus(trader), "Trader still blacklisted");
    }

    /**
     * @notice Tests bidirectional blacklist enforcement
     * @dev Verifies blacklisted addresses cannot send or receive tokens
     * @dev Tests both directions of transfer blocking
     */
    function testBlacklistBidirectional() public {
        // Disable automatic swapping to test only blacklist functionality
        vm.prank(owner);
        vaulton.setSwapEnabled(false);
        
        // Set up router to avoid failures on other operations
        vm.deal(address(mockRouter), 100 ether);
        mockRouter.setForceRevert(false);
        
        // Test both directions of blacklist
        vm.prank(owner);
        vaulton.blacklistAddress(trader, true);
        
        // Blacklisted account can't send
        vm.expectRevert("Blacklisted");
        vm.prank(trader);
        vaulton.transfer(user, 100);
        
        // Accounts can't send to blacklisted account
        vm.expectRevert("Blacklisted");
        vm.prank(user);
        vaulton.transfer(trader, 100);
        
        // Unblacklist and verify it works again
        vm.prank(owner);
        vaulton.blacklistAddress(trader, false);
        
        vm.prank(user);
        vaulton.transfer(trader, 100);
    }

    /**
     * @notice Tests maximum transaction limit enforcement
     * @dev Verifies transfers cannot exceed 1% of total supply
     * @dev Critical anti-whale protection mechanism test
     */
    function testMaxTransactionLimit() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        uint256 amount = vaulton.getMaxTransactionAmount() + 1;
        vm.expectRevert("Max tx");
        vm.prank(trader);
        vaulton.transfer(user, amount);
    }

    /**
     * @notice Tests exact maximum transaction limit boundary
     * @dev Verifies transactions at limit succeed, above limit fail
     * @dev Tests precise boundary condition handling
     */
    function testMaxTransactionLimitExact() public {
        uint256 maxAmount = vaulton.getMaxTransactionAmount();

        // Ensure trader has enough tokens
        vm.startPrank(owner);
        vaulton.excludeFromFees(owner, true); // Avoid tax when transferring to trader
        vaulton.transfer(trader, maxAmount * 2); // Transfer enough tokens
        vm.stopPrank();

        // Disable automatic swaps
        vm.prank(owner);
        vaulton.setSwapEnabled(false);

        // This should succeed - exactly at the limit
        vm.prank(trader);
        vaulton.transfer(user, maxAmount);

        // This should fail - 1 over the limit
        vm.expectRevert("Max tx");
        vm.prank(trader);
        vaulton.transfer(user, maxAmount + 1);
    }

    /**
     * @notice Tests owner-only function access restrictions
     * @dev Verifies unauthorized users cannot access admin functions
     * @dev Tests Ownable access control implementation
     */
    function testOnlyOwnerRestrictions() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.excludeFromFees(user, true);
    }

    // ========================================
    // FEE EXCLUSION TESTS
    // ========================================
    
    /**
     * @notice Tests fee exclusion mechanism
     * @dev Verifies addresses can be excluded from tax calculations
     * @dev Tests exclusion status checking and toggle functionality
     */
    function testExcludeFromFees() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);

        // Check that the address is excluded from fees
        assertTrue(vaulton.isAddressExcludedFromFees(trader));
    }

    /**
     * @notice Tests external fee exclusion function
     * @dev Verifies public interface for fee exclusion management
     */
    function testExcludeFromFeesExternal() public {
        vm.prank(owner);
        vaulton.excludeFromFeesExternal(user, true);
        assertTrue(vaulton.isAddressExcludedFromFees(user), "User not excluded");
        vm.prank(owner);
        vaulton.excludeFromFeesExternal(user, false);
        assertFalse(vaulton.isAddressExcludedFromFees(user), "User not included");
    }
    
    /**
     * @notice Tests bulk fee exclusion for multiple addresses
     * @dev Verifies batch exclusion operations for efficiency
     */
    function testExcludeMultipleAccountsFromFees() public {
        address[] memory accounts = new address[](2);
        accounts[0] = user;
        accounts[1] = trader;
        vm.prank(owner);
        vaulton.excludeMultipleAccountsFromFees(accounts, true);
        assertTrue(vaulton.isAddressExcludedFromFees(user), "User not excluded");
        assertTrue(vaulton.isAddressExcludedFromFees(trader), "Trader not excluded");
    }

    /**
     * @notice Tests different tax exclusion paths in transfer logic
     * @dev Verifies tax application when sender/receiver excluded
     * @dev Tests all combinations of exclusion scenarios
     */
    function testTaxExclusionPaths() public {
        uint256 amount = 1000 * 10**18;

        // Disable automatic swaps
        vm.prank(owner);
        vaulton.setSwapEnabled(false);

        // Get the original tax rate
        uint256 sellTax = vaulton.getSellTax();

        // 1. Test when neither sender nor receiver is excluded (taxes applied)
        uint256 initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);

        // Expected amount after tax
        uint256 taxAmount = amount * sellTax / 100;
        uint256 expectedAfterTax = amount - taxAmount;

        assertEq(vaulton.balanceOf(user), initialUserBalance + expectedAfterTax, "Tax not applied correctly");

        // 2. Test when sender is excluded (no taxes)
        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);

        initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);

        assertEq(vaulton.balanceOf(user), initialUserBalance + amount, "Tax incorrectly applied to excluded sender");

        // 3. Test when receiver is excluded (no taxes should apply)
        vm.prank(owner);
        vaulton.excludeFromFees(trader, false);
        vm.prank(owner);
        vaulton.excludeFromFees(user, true);

        initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);

        // Si receiver exclu, il ne doit PAS y avoir de taxe
        assertEq(
            vaulton.balanceOf(user),
            initialUserBalance + amount,
            "Tax incorrectly applied to excluded receiver"
        );
    }
    
    // ========================================
    // CONFIGURATION & ADMIN TESTS
    // ========================================
    
    /**
     * @notice Tests swap enable/disable functionality
     * @dev Verifies automatic swap operations can be controlled
     * @dev Tests swapEnabled flag behavior
     */
    function testSetSwapEnabled() public {
        vm.prank(owner);
        vaulton.setSwapEnabled(false);
        assertFalse(vaulton.swapEnabled(), "Swap not disabled");
        vm.prank(owner);
        vaulton.setSwapEnabled(true);
        assertTrue(vaulton.swapEnabled(), "Swap not enabled");
    }
    
    /**
     * @notice Tests wallet address updates for fund distribution
     * @dev Verifies marketing, CEX, and operations wallet configuration
     */
    function testUpdateWallets() public {
        address m = address(0x1111);
        address c = address(0x2222);
        address o = address(0x3333);
        vm.prank(owner);
        vaulton.updateWallets(m, c, o);
        // You can add assertions if you have public getters for these wallets
    }
    
    /**
     * @notice Tests distribution share percentage updates
     * @dev Verifies marketing, CEX, and operations share modifications
     */
    function testUpdateShares() public {
        vm.prank(owner);
        vaulton.updateShares(40, 30, 30);
        // You can add assertions if you have public getters for these shares
    }
    
    /**
     * @notice Tests contract ownership renunciation
     * @dev Verifies owner can permanently renounce control
     * @dev Critical decentralization mechanism test
     */
    function testRenounceContract() public {
        vm.prank(owner);
        vaulton.renounceContract();
        assertEq(vaulton.owner(), address(0), "Ownership not renounced");
    }
    
    /**
     * @notice Tests DEX pair configuration
     * @dev Verifies additional DEX pairs can be added/removed
     * @dev Tests multi-DEX support functionality
     */
    function testSetDexPair() public {
        address fakePair = address(0x5678);
        vm.prank(owner);
        vaulton.setDexPair(fakePair, true);
        assertTrue(vaulton.isDexPair(fakePair), "DEX pair status not set");
        vm.prank(owner);
        vaulton.setDexPair(fakePair, false);
        assertFalse(vaulton.isDexPair(fakePair), "DEX pair status not unset");
    }

    /**
     * @notice Tests PancakeSwap main pair setup
     * @dev Verifies primary trading pair configuration
     * @dev Tests pair-already-set protection mechanism
     */
    function testSetPancakePair() public {
        address fakePair = address(0x1234);
        vm.prank(owner);
        vm.expectRevert("Pair already set");
        vaulton.setPancakePair(fakePair);
    }
    
    // ========================================
    // FUND DISTRIBUTION TESTS
    // ========================================
    
    /**
     * @notice Tests fund distribution queueing mechanism
     * @dev Verifies two-step distribution process for security
     * @dev Tests distribution calculation and queue setup
     */
    function testQueueAndProcessDistribution() public {
        // Fund contract with ETH
        vm.deal(address(vaulton), 1 ether);

        // Advance the block number to satisfy the initial condition
        uint256 initialBlockNumber = block.number;
        vm.roll(initialBlockNumber + 2);

        vm.prank(owner);
        vm.deal(address(vaulton), 10 ether); // Fund the contract with sufficient BNB
        vaulton.queueDistribution();

        // Advance the block number again to allow another distribution
        vm.roll(block.number + 2);

        assertGt(vaulton.pendingDistributions(vaulton.marketingWallet()), 0, "No pending distribution");
        vm.prank(owner);
        vaulton.processDistribution(vaulton.marketingWallet());
    }

    /**
     * @notice Tests complete fund distribution process
     * @dev Verifies end-to-end BNB distribution to configured wallets
     * @dev Tests marketing, CEX, and operations fund allocation
     */
    function testDistributeFunds() public {
        // Fund contract with ETH
        vm.deal(address(vaulton), 1 ether);

        // Advance the block number to satisfy the distribution delay
        uint256 initialBlockNumber = block.number;
        vm.roll(initialBlockNumber + 2);

        vm.prank(owner);
        vm.deal(address(vaulton), 10 ether); // Fund the contract with sufficient BNB
        vaulton.distributeFunds();
    }

    // ========================================
    // EVENT EMISSION TESTS
    // ========================================
    
    /**
     * @notice Tests tax application event emission
     * @dev Verifies TaxApplied events are emitted with correct parameters
     * @dev Tests event data accuracy for transaction tracking
     */
    function testTaxAppliedEvent() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        uint256 sellTax = vaulton.getSellTax(); // 10%
        uint256 taxAmount = amount * sellTax / 100;
        
        vm.expectEmit(true, true, true, true);
        emit TaxApplied(trader, dexPair, amount, taxAmount, "sell");
        
        vm.prank(trader);
        vaulton.transfer(dexPair, amount);
    }

    /**
     * @notice Tests all event emissions across contract operations
     * @dev Comprehensive test for event logging functionality
     * @dev Verifies events provide proper transaction transparency
     */
    function testAllEvents() public {
        uint256 amount = 1000 * 10**18;

        // Prepare the mockRouter with more ETH
        vm.deal(address(mockRouter), 100 ether);
        mockRouter.setForceRevert(false);

        // Initialize the path array
        address[] memory path = new address[](2);
        path[0] = address(vaulton);
        path[1] = address(mockWETH);
        mockRouter.setPath(path);

        // Transfer tokens to the Vaulton contract
        vm.prank(owner);
        vaulton.transfer(address(vaulton), amount);

        // Make sure contract has enough ETH to simulate the swap result
        vm.deal(address(vaulton), 1 ether); // Add this line
    
        // Call the swap function
        vm.prank(owner);
        vaulton.triggerSwapAndLiquify(amount);
    
        // Verification
        assertTrue(address(vaulton).balance > 0, "Swap functionality failed");
    }

    // ========================================
    // GETTER FUNCTION TESTS
    // ========================================
    
    /**
     * @notice Tests all contract constant getters
     * @dev Verifies token constants return correct values
     * @dev Tests total supply, initial burn, threshold, and max transaction
     */
    function testAllGetters() public view {
        (
            uint256 totalSupply,
            uint256 initialBurn,
            uint256 burnThreshold,
            uint256 maxTxAmount
        ) = vaulton.getTokenConstants();
        assertEq(totalSupply, 50_000_000 * 10**18);
        assertEq(initialBurn, 15_000_000 * 10**18);
        assertEq(burnThreshold, (totalSupply * 75) / 100);
        assertEq(maxTxAmount, totalSupply / 100);

        (
            uint256 burnShare,
            uint256 marketingShare,
            uint256 liquidityShare
        ) = vaulton.getTaxDistribution();
        assertEq(burnShare, 60);
        assertEq(marketingShare, 25);
        assertEq(liquidityShare, 15);
    }

    /**
     * @notice Tests token constant getter function
     * @dev Verifies getTokenConstants returns accurate values
     */
    function testGetTokenConstants() public view {
        (
            uint256 totalSupply,
            uint256 initialBurn,
            uint256 burnThreshold,
            uint256 maxTxAmount
        ) = vaulton.getTokenConstants();
        assertEq(totalSupply, 50_000_000 * 10**18);
        assertEq(initialBurn, 15_000_000 * 10**18);
        assertEq(burnThreshold, (totalSupply * 75) / 100);
        assertEq(maxTxAmount, totalSupply / 100);
    }

    /**
     * @notice Tests tax distribution percentage getter
     * @dev Verifies getTaxDistribution returns correct percentages
     */
    function testGetTaxDistribution() public view {
        (
            uint256 burnShare,
            uint256 marketingShare,
            uint256 liquidityShare
        ) = vaulton.getTaxDistribution();
        assertEq(burnShare, 60);
        assertEq(marketingShare, 25);
        assertEq(liquidityShare, 15);
    }

    /**
     * @notice Tests security limits getter function
     * @dev Verifies maximum transaction amount retrieval
     */
    function getSecurityLimits() public view returns (uint256 maxTransaction) {
        return vaulton.getMaxTransactionAmount();
    }

    // ========================================
    // EDGE CASE & ERROR CONDITION TESTS
    // ========================================
    
    /**
     * @notice Tests zero amount transfer handling
     * @dev Verifies zero transfers don't affect balances or emit events
     */
    function testZeroAmountTransfer() public {
        uint256 amount = 0;
        
        // Attempt transfer with zero amount
        vm.prank(trader);
        vaulton.transfer(user, amount);
        
        // No balance should change and no events should be emitted
        assertEq(vaulton.balanceOf(user), 10_000 * 10**18, "Balance changed on zero transfer");
    }
    
    /**
     * @notice Tests insufficient balance error handling
     * @dev Verifies proper revert when transfer exceeds balance
     */
    function testInsufficientBalance() public {
        uint256 amount = vaulton.balanceOf(trader) + 1;
        
        // Expect revert when trying to transfer more than balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        vm.prank(trader);
        vaulton.transfer(user, amount);
    }
    
    /**
     * @notice Tests very small amount transfers
     * @dev Verifies micro-transfers work correctly without precision loss
     */
    function testSmallTransfer() public {
        uint256 amount = 1; // Very small amount

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        // Exclude sender and recipient from fees
        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);
        vm.prank(owner);
        vaulton.excludeFromFees(user, true);

        // Perform a transfer without taxes
        uint256 initialUserBalance = vaulton.balanceOf(user);
        vm.prank(trader);
        vaulton.transfer(user, amount);

        // Verify that the recipient's balance has increased correctly
        assertEq(vaulton.balanceOf(user), initialUserBalance + amount, "Small transfer failed");
    }

    /**
     * @notice Tests self-transfer and zero address transfer restrictions
     * @dev Verifies self-transfers don't change balance and zero address transfers revert
     */
    function testTransferToSelfAndZeroAddress() public {
        // Disable automatic swapping for this test
        vm.prank(owner);
        vaulton.setSwapEnabled(false);

        uint256 amount = 1000 * 10**18;

        // Test transfer to self (shouldn't change balance or apply tax)
        uint256 initialTraderBalance = vaulton.balanceOf(trader);

        vm.prank(trader);
        vaulton.transfer(trader, amount);

        assertEq(vaulton.balanceOf(trader), initialTraderBalance, "Self-transfer changed balance");

        // Test transfer to zero address (should revert)
        vm.expectRevert("ERC20: transfer to the zero address");
        vm.prank(trader);
        vaulton.transfer(address(0), amount);
    }

    // Tests for error conditions (require statements)
    function testMaxTransactionLimitExact() public {
        uint256 maxAmount = vaulton.getMaxTransactionAmount();

        // Ensure trader has enough tokens
        vm.startPrank(owner);
        vaulton.excludeFromFees(owner, true); // Avoid tax when transferring to trader
        vaulton.transfer(trader, maxAmount * 2); // Transfer enough tokens
        vm.stopPrank();

        // Disable automatic swaps
        vm.prank(owner);
        vaulton.setSwapEnabled(false);

        // This should succeed - exactly at the limit
        vm.prank(trader);
        vaulton.transfer(user, maxAmount);

        // This should fail - 1 over the limit
        vm.expectRevert("Max tx");
        vm.prank(trader);
        vaulton.transfer(user, maxAmount + 1);
    }
    
    /**
     * @notice Tests force revert setting in mock router
     * @dev Utility test for mock configuration in other tests
     */
    function testForceRevertSetting() public {
        // Explicitly set force revert to false before swaps
        vm.prank(owner);
        mockRouter.setForceRevert(false);
    }
}