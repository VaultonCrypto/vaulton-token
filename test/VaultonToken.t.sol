// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/VaultonToken.sol";

/**
 * @title MockRouter - PancakeSwap Router Mock for Testing
 * @dev Simplified mock implementation of PancakeSwap V2 Router
 * @notice This mock simulates real DEX behavior for comprehensive testing
 * Used for testing buyback mechanism without external dependencies
 */
contract MockRouter {
    address public WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    function factory() external view returns (address) {
        return address(this);
    }
    
    function getPair(address, address) external pure returns (address) {
        return address(0x1234567890123456789012345678901234567890);
    }
    
    /**
     * @dev Simulates selling tokens for BNB (1 token = 0.001 BNB for testing)
     * @notice Real implementation would interact with liquidity pools
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint,
        address[] calldata,
        address to,
        uint
    ) external {
        uint256 bnbAmount = amountIn / 1000;
        payable(to).transfer(bnbAmount);
    }
    
    /**
     * @dev Simulates buying tokens with BNB (1 BNB = 1000 tokens for testing)
     * @notice Real implementation would interact with liquidity pools
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint,
        address[] calldata path,
        address to,
        uint
    ) external payable {
        uint256 tokenAmount = msg.value * 1000;
        
        require(path.length == 2, "Invalid path");
        require(path[0] == WETH, "Invalid path start");
        
        Vaulton token = Vaulton(payable(path[1]));
        
        if (token.balanceOf(address(this)) >= tokenAmount) {
            token.transfer(to, tokenAmount);
        }
    }
    
    receive() external payable {}
}

/**
 * @title VaultonTest - Comprehensive Test Suite for Vaulton Token
 * @dev Complete testing framework covering all contract functionality
 * @notice Tests validate the revolutionary 36% buyback control mechanism
 * 
 * Key Testing Areas:
 * - Core buyback mechanism functionality
 * - Security validations and access controls
 * - Mathematical deflation guarantees
 * - PinkSale compatibility features
 * - View functions for transparency
 * - Edge cases and error handling
 */
contract VaultonTest is Test {
    Vaulton public vaulton;
    MockRouter public mockRouter;
    
    address public owner;
    address public user1;
    address public mockPair;
    
    // Token Economics Constants - Mirror contract values for validation
    uint256 constant TOTAL_SUPPLY = 30_000_000 * 10**18;        // 30M total supply
    uint256 constant INITIAL_BURN = 15_000_000 * 10**18;        // 50% initial burn
    uint256 constant BUYBACK_RESERVE = 5_400_000 * 10**18;      // 36% buyback control
    uint256 constant PRESALE_ALLOCATION = 3_300_000 * 10**18;   // 11% presale
    uint256 constant LIQUIDITY_ALLOCATION = 2_100_000 * 10**18; // 7% liquidity
    uint256 constant CEX_ALLOCATION = 2_700_000 * 10**18;       // 9% CEX listing
    uint256 constant FOUNDER_ALLOCATION = 1_500_000 * 10**18;   // 5% founder
    
    /**
     * @dev Test environment setup
     * @notice Deploys contract and configures test environment
     * - Deploys mock router with sufficient liquidity
     * - Sets up trading environment
     * - Allocates tokens for comprehensive testing
     */
    function setUp() public {
        owner = address(this);
        user1 = address(0x1111);
        mockPair = address(0x1234567890123456789012345678901234567890);
        
        // Deploy mock router with sufficient BNB for testing
        mockRouter = new MockRouter();
        vm.deal(address(mockRouter), 1000 ether);
        
        // Deploy Vaulton token with router integration
        vaulton = new Vaulton(address(mockRouter));
        
        // Provide sufficient tokens to mock router for buyback simulations
        vaulton.transfer(address(mockRouter), 5_000_000 * 10**18);
        
        // Configure trading environment
        vaulton.setPancakePair(mockPair);
        vaulton.enableTrading();
        
        // Fund contract with BNB for testing
        vm.deal(address(vaulton), 10 ether);
        
        // Allocate tokens to test accounts
        vaulton.transfer(user1, 100_000 * 10**18);
    }
    
    // ========================================
    // CORE FUNCTIONALITY TESTS
    // ========================================
    
    /**
     * @dev Validates correct deployment and tokenomics setup
     * @notice Critical test ensuring all initial parameters are correct
     * Validates:
     * - Token metadata (name, symbol)
     * - Initial burn implementation (50% of supply)
     * - Buyback reserve allocation (36% control)
     * - Owner token balance after all allocations
     */
    function testDeployment() public view {
        assertEq(vaulton.name(), "Vaulton");
        assertEq(vaulton.symbol(), "VAULTON");
        assertEq(vaulton.burnedTokens(), INITIAL_BURN);
        assertEq(vaulton.buybackTokensRemaining(), BUYBACK_RESERVE);
        assertEq(vaulton.balanceOf(address(vaulton)), BUYBACK_RESERVE);
        
        // Validate owner balance after all test allocations
        // Total: 30M - 15M(burned) - 5.4M(contract) - 5M(mock) - 0.1M(user1) = 4.5M
        uint256 expectedOwnerTokens = 4_500_000 * 10**18;
        assertEq(vaulton.balanceOf(owner), expectedOwnerTokens);
    }
    
    /**
     * @dev Tests core buyback selling mechanism
     * @notice Validates the first phase of the revolutionary buyback system
     * Tests:
     * - Token-to-BNB conversion through DEX
     * - Reserve depletion tracking
     * - Cycle initialization and state management
     * - Event emission for transparency
     */
    function testSellBuybackTokens() public {
        uint256 sellAmount = 150_000 * 10**18;
        uint256 initialRemaining = vaulton.buybackTokensRemaining();
        
        vaulton.sellBuybackTokens(sellAmount);
        
        // Validate reserve depletion
        assertEq(vaulton.buybackTokensRemaining(), initialRemaining - sellAmount);
        assertGt(vaulton.buybackBNBBalance(), 0);
        assertEq(vaulton.totalBuybackCycles(), 1);
        
        // Validate cycle tracking
        (uint256 tokensSold, uint256 bnbReceived, uint256 tokensBought, , , bool completed) = vaulton.getBuybackCycle(1);
        assertEq(tokensSold, sellAmount);
        assertGt(bnbReceived, 0);
        assertEq(tokensBought, 0);
        assertFalse(completed);
    }
    
    /**
     * @dev Validates security controls for selling mechanism
     * @notice Critical security test ensuring proper access control and limits
     * Tests:
     * - Zero amount rejection
     * - Reserve insufficiency protection
     * - Maximum transaction limit (0.5% of total supply)
     * - Owner-only access control
     */
    function testSellBuybackTokensValidations() public {
        vm.expectRevert("Amount must be positive");
        vaulton.sellBuybackTokens(0);
        
        uint256 tooLarge = BUYBACK_RESERVE + 1;
        vm.expectRevert("Insufficient buyback reserve");
        vaulton.sellBuybackTokens(tooLarge);
        
        uint256 tooMuch = (TOTAL_SUPPLY / 200) + 1; // > 0.5%
        vm.expectRevert("Max 0.5% per transaction");
        vaulton.sellBuybackTokens(tooMuch);
        
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.sellBuybackTokens(100_000 * 10**18);
    }
    
    /**
     * @dev Tests core buyback and burn mechanism
     * @notice Validates the second phase of the revolutionary buyback system
     * Tests:
     * - BNB-to-token conversion through DEX
     * - Automatic token burning for deflation
     * - Cycle completion and state reset
     * - Mathematical deflation guarantee
     */
    function testBuybackAndBurnSimplified() public {
        uint256 sellAmount = 150_000 * 10**18;
        vaulton.sellBuybackTokens(sellAmount);
        
        uint256 initialBurned = vaulton.burnedTokens();
        
        vaulton.buybackAndBurn();
        
        // Validate buyback completion
        assertEq(vaulton.buybackBNBBalance(), 0);
        assertGt(vaulton.burnedTokens(), initialBurned);
        
        // Validate cycle completion
        (, , uint256 tokensBought, uint256 tokensBurned, , bool completed) = vaulton.getBuybackCycle(1);
        assertGt(tokensBought, 0);
        assertEq(tokensBurned, tokensBought);
        assertTrue(completed);
    }
    
    /**
     * @dev Validates security controls for buyback mechanism
     * @notice Ensures proper state validation and access control
     * Tests:
     * - BNB availability requirement
     * - Owner-only access control
     * - Proper error handling
     */
    function testBuybackAndBurnValidations() public {
        vm.expectRevert("No BNB available for buyback");
        vaulton.buybackAndBurn();
        
        vaulton.sellBuybackTokens(100_000 * 10**18);
        
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.buybackAndBurn();
    }
    
    /**
     * @dev Tests complete buyback cycle integration
     * @notice Validates end-to-end buyback process
     * Tests:
     * - Full cycle execution (sell -> buyback -> burn)
     * - State consistency throughout process
     * - Mathematical accuracy of deflation
     * - Proper cycle tracking and completion
     */
    function testCompleteBuybackCycleSimplified() public {
        uint256 sellAmount = 150_000 * 10**18;
        uint256 initialBurned = vaulton.burnedTokens();
        uint256 initialRemaining = vaulton.buybackTokensRemaining();
        
        vaulton.sellBuybackTokens(sellAmount);
        vaulton.buybackAndBurn();
        
        // Validate final state
        assertEq(vaulton.buybackTokensRemaining(), initialRemaining - sellAmount);
        assertGt(vaulton.burnedTokens(), initialBurned);
        assertEq(vaulton.buybackBNBBalance(), 0);
        assertEq(vaulton.totalBuybackCycles(), 1);
        
        // Validate cycle data integrity
        (, , uint256 tokensBought, uint256 tokensBurned, , bool completed) = vaulton.getBuybackCycle(1);
        assertGt(tokensBought, 0);
        assertEq(tokensBurned, tokensBought);
        assertTrue(completed);
    }
    
    /**
     * @dev Tests multiple consecutive buyback cycles
     * @notice Validates system performance under repeated operations
     * Tests:
     * - Multiple cycle execution without cooldown restrictions
     * - Cumulative deflation effects
     * - State consistency across cycles
     * - Cycle numbering and tracking accuracy
     */
    function testMultipleBuybackCyclesSimplified() public {
        for(uint i = 1; i <= 3; i++) {
            // Execute immediate consecutive cycles (no cooldown)
            vaulton.sellBuybackTokens(100_000 * 10**18);
            vaulton.buybackAndBurn();
            
            assertEq(vaulton.totalBuybackCycles(), i);
            
            // Validate each cycle completion
            (, , uint256 tokensBought, uint256 tokensBurned, , bool completed) = vaulton.getBuybackCycle(i);
            assertGt(tokensBought, 0);
            assertEq(tokensBurned, tokensBought);
            assertTrue(completed);
        }
    }
    
    /**
     * @dev Tests comprehensive sell mechanism functionality
     * @notice Validates cumulative effects of multiple buyback operations
     * Tests:
     * - Progressive reserve depletion
     * - Cumulative deflation measurement
     * - State consistency across multiple operations
     * - Mathematical accuracy of token economics
     */
    function testSellMechanismCore() public {
        uint256 initialBurned = vaulton.burnedTokens();
        uint256 initialBuybackReserve = vaulton.buybackTokensRemaining();
        
        uint256 cyclesCount = 3;
        uint256 sellAmount = 100_000 * 10**18;
        
        for(uint i = 0; i < cyclesCount; i++) {
            vaulton.sellBuybackTokens(sellAmount);
            assertGt(vaulton.buybackBNBBalance(), 0);
            
            vaulton.buybackAndBurn();
        }
        
        // Validate cumulative effects
        assertEq(vaulton.totalBuybackCycles(), cyclesCount);
        assertEq(vaulton.buybackTokensRemaining(), initialBuybackReserve - (sellAmount * cyclesCount));
        assertGt(vaulton.burnedTokens(), initialBurned);
        assertEq(vaulton.buybackBNBBalance(), 0);
        
        // Verify mathematical deflation occurred
        uint256 finalCirculating = TOTAL_SUPPLY - vaulton.burnedTokens();
        uint256 initialCirculating = TOTAL_SUPPLY - initialBurned;
        assertLt(finalCirculating, initialCirculating);
    }
    
    /**
     * @dev Tests buyback reserve exhaustion scenarios
     * @notice Validates system behavior at operational limits
     * Tests:
     * - Multiple cycles within transaction limits (0.5% max)
     * - Reserve depletion tracking accuracy
     * - Transaction limit enforcement
     * - Reserve insufficiency protection
     */
    function testBuybackExhaustion() public {
        uint256 initialRemaining = vaulton.buybackTokensRemaining();
        
        // Use maximum allowed transaction size (0.5% of total supply)
        // Max per transaction = 30M / 200 = 150K tokens
        uint256 sellAmount = 150_000 * 10**18;
        
        // Execute 5 cycles with maximum allowed amounts
        for(uint i = 0; i < 5; i++) {
            if (vaulton.buybackTokensRemaining() >= sellAmount) {
                vaulton.sellBuybackTokens(sellAmount);
                vaulton.buybackAndBurn();
            }
        }
        
        // Validate reserve depletion (5 x 150K = 750K tokens used)
        uint256 expectedRemaining = initialRemaining - (5 * sellAmount);
        assertEq(vaulton.buybackTokensRemaining(), expectedRemaining);
        
        // Test transaction limit enforcement
        uint256 maxAllowed = TOTAL_SUPPLY / 200; // 150K tokens
        vm.expectRevert("Max 0.5% per transaction");
        vaulton.sellBuybackTokens(maxAllowed + 1);
        
        // Test reserve insufficiency protection
        uint256 remaining = vaulton.buybackTokensRemaining();
        if (remaining > 0 && remaining < maxAllowed) {
            vm.expectRevert("Insufficient buyback reserve");
            vaulton.sellBuybackTokens(remaining + 1);
        }
    }
    
    /**
     * @dev Tests rapid consecutive buyback operations
     * @notice Validates system performance under high-frequency operations
     * Tests:
     * - Immediate consecutive operations (no cooldown)
     * - Gas efficiency under repeated calls
     * - State consistency under rapid execution
     * - Cumulative reserve depletion accuracy
     */
    function testRapidConsecutiveBuybacks() public {
        uint256 sellAmount = 50_000 * 10**18;
        
        // Execute 5 rapid consecutive buyback cycles
        for(uint i = 1; i <= 5; i++) {
            vaulton.sellBuybackTokens(sellAmount);
            vaulton.buybackAndBurn();
            
            assertEq(vaulton.totalBuybackCycles(), i);
            assertEq(vaulton.buybackBNBBalance(), 0);
        }
        
        // Validate cumulative token usage
        uint256 expectedRemaining = BUYBACK_RESERVE - (sellAmount * 5);
        assertEq(vaulton.buybackTokensRemaining(), expectedRemaining);
    }
    
    // ========================================
    // TRANSPARENCY & VIEW FUNCTION TESTS
    // ========================================
    
    /**
     * @dev Tests tokenomics transparency function
     * @notice Critical test for investor and auditor transparency
     * Validates:
     * - Accurate total supply reporting
     * - Correct circulating supply calculation
     * - Burned tokens tracking accuracy
     * - Reserve allocation verification
     * - Community allocation calculations
     */
    function testGetTokenomics() public view {
        (
            uint256 totalSupply,
            uint256 circulatingSupply,
            uint256 burnedTokens_,
            uint256 buybackReserve,
            uint256 founderAllocation,
            uint256 communityAllocation
        ) = vaulton.getTokenomics();
        
        assertEq(totalSupply, TOTAL_SUPPLY);
        assertEq(circulatingSupply, TOTAL_SUPPLY - INITIAL_BURN);
        assertEq(burnedTokens_, INITIAL_BURN);
        assertEq(buybackReserve, BUYBACK_RESERVE);
        assertEq(founderAllocation, FOUNDER_ALLOCATION);
        
        uint256 expectedCommunity = PRESALE_ALLOCATION + LIQUIDITY_ALLOCATION + CEX_ALLOCATION;
        assertEq(communityAllocation, expectedCommunity);
    }
    
    /**
     * @dev Tests buyback statistics transparency
     * @notice Essential for monitoring the revolutionary 36% buyback control
     * Validates:
     * - Remaining buyback tokens accuracy
     * - Used tokens calculation
     * - BNB balance tracking
     * - Control percentage calculation (36% initial)
     * - Cycle completion counter
     */
    function testGetBuybackStats() public view {
        (
            uint256 tokensRemaining,
            uint256 tokensUsed,
            uint256 bnbBalance,
            uint256 totalBurned,
            uint256 controlPercentage,
            uint256 cyclesCompleted,
            bool nextCycleReady
        ) = vaulton.getBuybackStats();
        
        assertEq(tokensRemaining, BUYBACK_RESERVE);
        assertEq(tokensUsed, 0);
        assertEq(bnbBalance, 0);
        assertEq(totalBurned, INITIAL_BURN);
        assertEq(cyclesCompleted, 0);
        assertFalse(nextCycleReady);
        
        // Validate 36% buyback control calculation
        uint256 circulatingSupply = TOTAL_SUPPLY - INITIAL_BURN;
        uint256 expectedControl = (BUYBACK_RESERVE * 100) / circulatingSupply;
        assertEq(controlPercentage, expectedControl);
    }
    
    /**
     * @dev Tests security status reporting
     * @notice Critical for auditors and security assessment
     * Validates:
     * - Buyback control percentage (36%)
     * - Trading activation status
     * - Liquidity pair configuration
     * - Contract token balance
     * - Community control distribution
     */
    function testGetSecurityStatus() public view {
        (
            uint256 buybackControlPercentage,
            bool tradingActive,
            bool pairSet,
            uint256 contractBalance,
            uint256 communityControl
        ) = vaulton.getSecurityStatus();
        
        assertEq(buybackControlPercentage, 36); // Revolutionary 36% control
        assertTrue(tradingActive);
        assertTrue(pairSet);
        assertEq(contractBalance, BUYBACK_RESERVE);
        
        uint256 communityTokens = PRESALE_ALLOCATION + LIQUIDITY_ALLOCATION + CEX_ALLOCATION;
        uint256 expectedCommunityControl = (communityTokens * 100) / TOTAL_SUPPLY;
        assertEq(communityControl, expectedCommunityControl);
    }

    /**
     * @dev Tests buyback cycle data validation
     * @notice Ensures proper cycle tracking and data integrity
     * Tests:
     * - Invalid cycle ID rejection
     * - Cycle numbering validation
     * - Data retrieval accuracy
     */
    function testGetBuybackCycleValidations() public {
        vm.expectRevert("Invalid cycle ID");
        vaulton.getBuybackCycle(0);
        
        vm.expectRevert("Invalid cycle ID");
        vaulton.getBuybackCycle(999);
    }
    
    /**
     * @dev Tests quick statistics dashboard function
     * @notice Provides essential metrics for quick assessment
     * Validates:
     * - Burn progress percentage (50% initial)
     * - Buyback power percentage (36% control)
     * - Current circulating supply
     * - Trading status confirmation
     */
    function testGetQuickStats() public view {
        (
            uint256 burnProgress,
            uint256 buybackPower,
            uint256 circulatingSupply,
            bool trading
        ) = vaulton.getQuickStats();
        
        assertEq(burnProgress, 50); // 50% initial burn
        assertEq(buybackPower, 36); // 36% buyback control
        assertEq(circulatingSupply, TOTAL_SUPPLY - INITIAL_BURN);
        assertTrue(trading);
    }
    
    // ========================================
    // SECURITY & ACCESS CONTROL TESTS
    // ========================================
    
    /**
     * @dev Tests critical access control mechanisms
     * @notice Essential security test for owner-only functions
     * Validates:
     * - Buyback function access restriction
     * - Administrative function protection
     * - Proper error messaging for unauthorized access
     */
    function testOnlyOwnerFunctions() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.sellBuybackTokens(100_000 * 10**18);
        
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.buybackAndBurn();
        
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.setPancakePair(address(0x9999));
        
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.enableTrading();
        
        vm.stopPrank();
    }
    
    /**
     * @dev Tests liquidity pair configuration security
     * @notice Validates one-time pair setting mechanism
     * Tests:
     * - Pair already set protection
     * - Invalid pair validation through factory
     * - Security against unauthorized pair changes
     */
    function testSetPancakePairValidations() public {
        // Test pair already set protection
        vm.expectRevert("Pair already set");
        vaulton.setPancakePair(mockPair);
        
        // Test invalid pair validation
        Vaulton newToken = new Vaulton(address(mockRouter));
        vm.expectRevert("Invalid pair contract");
        newToken.setPancakePair(address(0x9999));
    }

    /**
     * @dev Tests trading enablement security
     * @notice Validates one-time trading activation
     * Tests:
     * - Trading already enabled protection
     * - One-time activation enforcement
     */
    function testEnableTradingValidations() public {
        vm.expectRevert("Trading already enabled");
        vaulton.enableTrading();
    }
    
    /**
     * @dev Tests transfer restrictions before trading
     * @notice Validates controlled launch mechanism
     * Tests:
     * - Owner transfer privileges before launch
     * - User transfer restrictions before trading
     * - Proper error handling for restricted transfers
     */
    function testTransferBeforeTradingEnabled() public {
        Vaulton newToken = new Vaulton(address(mockRouter));
        
        // Should allow owner transfers for setup
        newToken.transfer(user1, 1000 * 10**18);
        
        // Should block user-to-user transfers before trading
        vm.prank(user1);
        vm.expectRevert("Trading not enabled");
        newToken.transfer(address(0x2222), 100 * 10**18);
    }
    
    /**
     * @dev Tests PinkSale compatibility functions
     * @notice Critical for PinkSale FairLaunch approval
     * Validates:
     * - Owner identification function
     * - Tax status reporting (zero taxes)
     * - Renouncement status checking
     * - Mint function availability (none)
     * - Burn function availability (yes)
     */
    function testOwnershipFunctions() public view {
        assertEq(vaulton.getOwner(), owner);
        assertFalse(vaulton.hasTax());        // Zero taxes
        assertFalse(vaulton.isRenounced());   // Owner not renounced
        assertFalse(vaulton.hasMintFunction()); // No mint capability
        assertTrue(vaulton.hasBurnFunction());  // Burn capability for deflation
    }
    
    /**
     * @dev Tests BNB receiving capability
     * @notice Validates contract's ability to receive BNB for operations
     * Essential for buyback mechanism funding
     */
    function testReceiveFunction() public {
        uint256 initialBalance = address(vaulton).balance;
        
        payable(address(vaulton)).transfer(1 ether);
        
        assertEq(address(vaulton).balance, initialBalance + 1 ether);
    }
    
    receive() external payable {}
}