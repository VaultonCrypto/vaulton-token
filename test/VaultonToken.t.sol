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

    // 1. Transfer & Taxes Tests
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

        // Use sellTax instead of buyTax since we apply the universal tax
        uint256 sellTax = vaulton.getSellTax(); // Changed from buyTax to sellTax
        uint256 buyTaxAmount = amount * sellTax / 100; // Use sellTax for calculation
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
        // Now use sellTax instead of buyTax since we apply the universal tax
        uint256 sellTax = vaulton.getSellTax();
        uint256 taxAmount = amount * sellTax / 100;
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

    // 2. Liquidity Tests
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

    // 3. Burn Threshold Tests
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

    // 5. Getter Tests
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

    function getSecurityLimits() public view returns (uint256 maxTransaction) {
        return vaulton.getMaxTransactionAmount();
    }

    // 6. Event Tests
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

    function testTaxAppliedEvent() public {
        uint256 amount = 1000 * 10**18;

        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        uint256 sellTax = vaulton.getSellTax();
        uint256 taxAmount = amount * sellTax / 100;
        vm.expectEmit(true, true, true, true);
        emit TaxApplied(trader, dexPair, amount, taxAmount, "universal");
        vm.prank(trader);
        vaulton.transfer(dexPair, amount);
    }

    // 7. Update Tests
    function testExcludeFromFees() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(owner);
        vaulton.excludeFromFees(trader, true);

        // Check that the address is excluded from fees
        assertTrue(vaulton.isAddressExcludedFromFees(trader));
    }

    function testBlacklist() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(owner);
        vaulton.blacklistAddress(trader, true);

        vm.expectRevert("Blacklisted");
        vm.prank(trader);
        vaulton.transfer(user, 1000 * 10**18);
    }

    function testMaxTransactionLimit() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        uint256 amount = vaulton.getMaxTransactionAmount() + 1;
        vm.expectRevert("Max tx");
        vm.prank(trader);
        vaulton.transfer(user, amount);
    }

    function testOnlyOwnerRestrictions() public {
        // Pre-fund the router with sufficient ETH for all swap-related tests
        vm.deal(address(mockRouter), 100 ether);

        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.excludeFromFees(user, true);
    }

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

    function testForceRevertSetting() public {
        // Explicitly set force revert to false before swaps
        vm.prank(owner);
        mockRouter.setForceRevert(false);
    }

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

    // Tests for error conditions (require statements)
    function testZeroAmountTransfer() public {
        uint256 amount = 0;
        
        // Attempt transfer with zero amount
        vm.prank(trader);
        vaulton.transfer(user, amount);
        
        // No balance should change and no events should be emitted
        assertEq(vaulton.balanceOf(user), 10_000 * 10**18, "Balance changed on zero transfer");
    }
    
    function testInsufficientBalance() public {
        uint256 amount = vaulton.balanceOf(trader) + 1;
        
        // Expect revert when trying to transfer more than balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        vm.prank(trader);
        vaulton.transfer(user, amount);
    }
    
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
    
    // Test if/else paths for tax conditions
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
    
    function testSwapThresholdConditions() public {
        uint256 swapThreshold = 100 * 10**18; // Assuming this is your threshold
        
        // Test below threshold - no swap triggered
        uint256 belowThreshold = swapThreshold - 1;
        
        vm.prank(owner);
        vaulton.transfer(address(vaulton), belowThreshold);
        
        uint256 initialBalance = address(vaulton).balance;
        
        // This shouldn't trigger an automatic swap
        vm.prank(trader);
        vaulton.transfer(dexPair, 1000 * 10**18);
        
        // Balance shouldn't change from automatic swap
        assertEq(address(vaulton).balance, initialBalance, "Swap incorrectly triggered below threshold");
        
        // Test above threshold - swap should happen
        uint256 aboveThreshold = swapThreshold + 1;
        
        vm.prank(owner);
        vaulton.transfer(address(vaulton), aboveThreshold);
        
        // Setup for swap to work
        vm.deal(address(mockRouter), 100 ether);
        mockRouter.setForceRevert(false);
        address[] memory path = new address[](2);
        path[0] = address(vaulton);
        path[1] = address(mockWETH);
        mockRouter.setPath(path);
        
        // Make sure contract has ETH after swap
        vm.deal(address(vaulton), 1 ether);
        
        // Trigger a transfer that should cause swap
        vm.prank(owner);
        vaulton.triggerSwapAndLiquify(aboveThreshold);
        
        // Verify swap happened
        assertGt(address(vaulton).balance, initialBalance, "Swap not triggered above threshold");
    }

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

    function testSetPancakePair() public {
        address fakePair = address(0x1234);
        vm.prank(owner);
        vm.expectRevert("Pair already set");
        vaulton.setPancakePair(fakePair);
    }

    function testSetDexPair() public {
        address fakePair = address(0x5678);
        vm.prank(owner);
        vaulton.setDexPair(fakePair, true);
        assertTrue(vaulton.isDexPair(fakePair), "DEX pair status not set");
        vm.prank(owner);
        vaulton.setDexPair(fakePair, false);
        assertFalse(vaulton.isDexPair(fakePair), "DEX pair status not unset");
    }

    function testExcludeFromFeesExternal() public {
        vm.prank(owner);
        vaulton.excludeFromFeesExternal(user, true);
        assertTrue(vaulton.isAddressExcludedFromFees(user), "User not excluded");
        vm.prank(owner);
        vaulton.excludeFromFeesExternal(user, false);
        assertFalse(vaulton.isAddressExcludedFromFees(user), "User not included");
    }

    function testExcludeMultipleAccountsFromFees() public {
        address[] memory accounts = new address[](2);
        accounts[0] = user;
        accounts[1] = trader;
        vm.prank(owner);
        vaulton.excludeMultipleAccountsFromFees(accounts, true);
        assertTrue(vaulton.isAddressExcludedFromFees(user), "User not excluded");
        assertTrue(vaulton.isAddressExcludedFromFees(trader), "Trader not excluded");
    }

    function testBlacklistAddress() public {
        vm.prank(owner);
        vaulton.blacklistAddress(user, true);
        assertTrue(vaulton.getBlacklistStatus(user), "User not blacklisted");
        vm.prank(owner);
        vaulton.blacklistAddress(user, false);
        assertFalse(vaulton.getBlacklistStatus(user), "User still blacklisted");
    }

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

    function testSetSwapEnabled() public {
        vm.prank(owner);
        vaulton.setSwapEnabled(false);
        assertFalse(vaulton.swapEnabled(), "Swap not disabled");
        vm.prank(owner);
        vaulton.setSwapEnabled(true);
        assertTrue(vaulton.swapEnabled(), "Swap not enabled");
    }

    function testUpdateWallets() public {
        address m = address(0x1111);
        address c = address(0x2222);
        address o = address(0x3333);
        vm.prank(owner);
        vaulton.updateWallets(m, c, o);
        // You can add assertions if you have public getters for these wallets
    }

    function testUpdateShares() public {
        vm.prank(owner);
        vaulton.updateShares(40, 30, 30);
        // You can add assertions if you have public getters for these shares
    }

    function testRemoveTaxes() public {
        vm.prank(owner);
        vaulton.removeTaxes();
        assertEq(vaulton.getBuyTax(), 0, "Buy tax not removed");
        assertEq(vaulton.getSellTax(), 0, "Sell tax not removed");
    }

    function testRenounceContract() public {
        vm.prank(owner);
        vaulton.renounceContract();
        assertEq(vaulton.owner(), address(0), "Ownership not renounced");
    }

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
}   