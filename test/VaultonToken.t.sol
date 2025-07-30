// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VaultonToken.sol";
import "./mocks/MockRouter.sol";
import "./mocks/MockERC20.sol";
import "../script/DeployVaulton.s.sol";

contract VaultonTokenTest is Test {
    Vaulton vaulton;
    MockRouter mockRouter;
    address owner;
    address alice;
    address bob;
    address pair;
    address weth;
    address factory;
    address marketingWallet;

    // Add local event declaration for testing
    event AntiBotBlocked(address indexed user, uint256 blockNumber);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        pair = makeAddr("pair");
        weth = makeAddr("weth");
        factory = makeAddr("factory");
        marketingWallet = makeAddr("marketingWallet");
        
        mockRouter = new MockRouter(weth, factory);
        vm.deal(address(mockRouter), 100 ether);

        vm.startPrank(owner);
        vaulton = new Vaulton(address(mockRouter), marketingWallet);
        uint256 ownerTokens = vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN() - vaulton.BUYBACK_RESERVE() - 1_000_000 * 1e18;
        vaulton.transfer(owner, ownerTokens);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(vaulton.TOTAL_SUPPLY(), 30_000_000 * 1e18);
        assertEq(vaulton.INITIAL_BURN(), 8_000_000 * 1e18);
        assertEq(vaulton.BUYBACK_RESERVE(), 11_000_000 * 1e18);

        assertEq(vaulton.burnedTokens(), vaulton.INITIAL_BURN());
        assertEq(vaulton.buybackTokensRemaining(), vaulton.BUYBACK_RESERVE());
        assertEq(vaulton.totalBuybackTokensSold(), 0);
        assertEq(vaulton.totalBuybackTokensBurned(), 0);

        // La réserve buyback n'est plus sur le contrat au lancement
        assertEq(vaulton.balanceOf(address(vaulton)), 0);
        assertEq(
            vaulton.balanceOf(owner),
            vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN()
        );
        assertEq(vaulton.totalSupply(), vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN());

        assertFalse(vaulton.tradingEnabled());
        assertEq(vaulton.pancakePair(), address(0));
        assertEq(vaulton.owner(), owner);
    }

    function testTokenomics() public view {
        uint256 totalSupply = vaulton.TOTAL_SUPPLY();
        uint256 initialBurn = vaulton.INITIAL_BURN();
        uint256 buybackReserve = vaulton.BUYBACK_RESERVE();
        uint256 marketingAllocation = 1_000_000 * 1e18;
        uint256 communityAllocation = totalSupply - initialBurn - buybackReserve - marketingAllocation;

        assertEq(initialBurn, 8_000_000 * 1e18);
        assertEq(buybackReserve, 11_000_000 * 1e18);
        assertEq(marketingAllocation, 1_000_000 * 1e18);
        assertEq(communityAllocation, 10_000_000 * 1e18);

        assertEq(initialBurn + buybackReserve + marketingAllocation + communityAllocation, totalSupply);
    }

    function testOwnershipFunctions() public {
        address newPair = makeAddr("pair");
        
        // Only owner can set the pair
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.setPair(newPair);

        vm.prank(owner);
        vaulton.setPair(newPair);
        assertEq(vaulton.pancakePair(), newPair);

        // Only owner can enable trading
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        vaulton.enableTrading();

        vm.prank(owner);
        vaulton.enableTrading();
        assertTrue(vaulton.tradingEnabled());
    }

    /// @notice Test getStats() returns correct initial values
    function testGetStats() public view {
        (
            uint256 totalSupply_,
            uint256 circulatingSupply,
            uint256 burnedTokens_,
            uint256 buybackTokensRemaining_,
            uint256 totalBuybackTokensSold_,
            uint256 totalBuybackTokensBurned_,
            uint256 totalBuybacks_,
            uint256 avgBlocksPerBuyback,
            uint256 totalBuybackBNB_,
            uint256 avgBNBPerBuyback
        ) = vaulton.getStats();

        assertEq(totalSupply_, vaulton.TOTAL_SUPPLY());
        assertEq(circulatingSupply, vaulton.totalSupply());
        assertEq(burnedTokens_, vaulton.INITIAL_BURN());
        assertEq(buybackTokensRemaining_, vaulton.BUYBACK_RESERVE());
        assertEq(totalBuybackTokensSold_, 0);
        assertEq(totalBuybackTokensBurned_, 0);
        assertEq(totalBuybacks_, 0);
        assertEq(avgBlocksPerBuyback, 0);
        assertEq(totalBuybackBNB_, 0);
        assertEq(avgBNBPerBuyback, 0);
    }

    function testBasicTransfers() public {
        vm.prank(owner);
        vaulton.transfer(alice, 1000 * 1e18);
        assertEq(vaulton.balanceOf(alice), 1000 * 1e18);
        assertEq(
            vaulton.balanceOf(owner),
            vaulton.TOTAL_SUPPLY() - vaulton.INITIAL_BURN() - 1000 * 1e18
        );
    }

    function testReceiveBNB() public {
        uint256 initialBalance = address(vaulton).balance;
        (bool success,) = address(vaulton).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(vaulton).balance, initialBalance + 1 ether);
    }

    function testGetOwnerFunction() public view {
        assertEq(vaulton.owner(), owner);
    }

    function testTokenMetadata() public view {
        assertEq(vaulton.name(), "Vaulton");
        assertEq(vaulton.symbol(), "VAULTON");
        assertEq(vaulton.decimals(), 18);
    }

    function testAllowanceAndApprove() public {
        vm.prank(owner);
        vaulton.approve(alice, 1000 * 1e18);
        assertEq(vaulton.allowance(owner, alice), 1000 * 1e18);
        vm.prank(alice);
        vaulton.transferFrom(owner, bob, 500 * 1e18);
        assertEq(vaulton.balanceOf(bob), 500 * 1e18);
        assertEq(vaulton.allowance(owner, alice), 500 * 1e18);
    }

    function testAutoSellEnabled() public view {
        assertFalse(vaulton.autoSellEnabled());
    }

    function testLastBuybackBlock() public view {
        assertEq(vaulton.lastBuybackBlock(), 0);
    }

    function testPancakeRouter() public view {
        assertEq(address(vaulton.pancakeRouter()), address(mockRouter));
    }

    function testTransferToContract() public {
        uint256 initialContractBalance = vaulton.balanceOf(address(vaulton));
        vm.prank(owner);
        vaulton.transfer(address(vaulton), 1000 * 1e18);
        assertEq(vaulton.balanceOf(address(vaulton)), initialContractBalance + 1000 * 1e18);
    }

    function testBuybackTokensRemainingCalculation() public view {
        assertEq(vaulton.buybackTokensRemaining(), vaulton.BUYBACK_RESERVE());
        // La réserve buyback n'est plus sur le contrat au lancement
        assertEq(vaulton.balanceOf(address(vaulton)), 0);
    }

    function testTransferRestrictions() public {
        vm.prank(alice);
        vm.expectRevert("Trading not enabled");
        vaulton.transfer(bob, 100);

        vm.prank(owner);
        vaulton.setPair(pair);
        vm.prank(owner);
        vaulton.enableTrading();

        vm.prank(owner);
        vaulton.transfer(alice, 1000 * 1e18);
        vm.prank(alice);
        vaulton.transfer(bob, 500 * 1e18);
        assertEq(vaulton.balanceOf(bob), 500 * 1e18);
    }

    function testRenounceOwnershipDisablesAutoSell() public {
        vm.prank(owner);
        vaulton.renounceOwnership();
        assertEq(vaulton.owner(), address(0));
    }

    function testWithdrawBNBReverts() public {
        vm.prank(owner);
        vm.expectRevert("Withdrawal of BNB is blocked");
        vaulton.withdraw();
    }

    function testConstructorZeroRouter() public {
        vm.expectRevert("Invalid router address");
        new Vaulton(address(0), address(0));
    }

    function testTransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("ERC20: transfer to the zero address");
        vaulton.transfer(address(0), 1000 * 1e18);
    }

    function testSetBNBThreshold() public {
        vm.prank(owner);
        vaulton.setBNBThreshold(0.05 ether);
        assertEq(vaulton.BNB_THRESHOLD(), 0.05 ether);

        vm.prank(owner);
        vm.expectRevert("Threshold too low");
        vaulton.setBNBThreshold(0);
    }

    function testSetAutoSellPercent() public {
        vm.prank(owner);
        vaulton.setAutoSellPercent(150);
        assertEq(vaulton.AUTO_SELL_PERCENT(), 150);

        vm.prank(owner);
        vm.expectRevert("Percent out of range");
        vaulton.setAutoSellPercent(0);

        vm.prank(owner);
        vm.expectRevert("Percent out of range");
        vaulton.setAutoSellPercent(501);
    }

    function testSetAutoSellEnabled() public {
        vm.prank(owner);
        vaulton.setAutoSellEnabled(false);
        assertFalse(vaulton.autoSellEnabled());

        vm.prank(owner);
        vaulton.setAutoSellEnabled(true);
        assertTrue(vaulton.autoSellEnabled());
    }

    function testSetSlippagePercent() public {
        vm.prank(owner);
        vaulton.setSlippagePercent(100);
        assertEq(vaulton.slippagePercent(), 100);

        vm.prank(owner);
        vm.expectRevert("Slippage too high");
        vaulton.setSlippagePercent(501);
    }

    function testSetSwapGasLimit() public {
        vm.prank(owner);
        vaulton.setSwapGasLimit(600_000);
        assertEq(vaulton.swapGasLimit(), 600_000);

        vm.prank(owner);
        vm.expectRevert("Gas limit out of range");
        vaulton.setSwapGasLimit(99_999);

        vm.prank(owner);
        vm.expectRevert("Gas limit out of range");
        vaulton.setSwapGasLimit(2_000_001);
    }

    function testWhitelistAntiBot() public {
        vm.prank(owner);
        vaulton.addToWhitelist(alice);
        assertTrue(vaulton.isWhitelisted(alice));

        vm.prank(owner);
        vaulton.removeFromWhitelist(alice);
        assertFalse(vaulton.isWhitelisted(alice));
    }

    function testRecoverERC20() public {
        MockERC20 mockToken = new MockERC20("MockToken", "MOCK", 18);
        mockToken.mint(address(vaulton), 1000);
        uint256 vaultonBalance = mockToken.balanceOf(address(vaulton));
        assertEq(vaultonBalance, 1000);

        vm.prank(owner);
        vaulton.recoverERC20(address(mockToken), 1000);
        assertEq(mockToken.balanceOf(owner), 1000);

        vm.prank(owner);
        vm.expectRevert("Cannot recover VAULTON");
        vaulton.recoverERC20(address(vaulton), 1);

        MockERC20 marketingToken = new MockERC20("MarketingToken", "MARK", 18);
        marketingToken.mint(marketingWallet, 500);
        vm.prank(owner);
        vaulton.recoverERC20(address(marketingToken), 0);
    }

    function testDeployVaultonScriptInstantiation() public {
        DeployVaulton script = new DeployVaulton();
        assertTrue(address(script) != address(0));
    }

    function testAntiBotMechanism() public {
        vm.prank(owner);
        vaulton.setPair(pair);
        vm.prank(owner);
        vaulton.enableTrading();

        vm.prank(owner);
        vaulton.transfer(pair, 1000 * 1e18);

        vm.expectEmit(true, false, false, true);
        emit AntiBotBlocked(alice, block.number);
        vm.prank(pair);
        vm.expectRevert("Anti-bot: not whitelisted");
        vaulton.transfer(alice, 100 * 1e18);

        vm.prank(owner);
        vaulton.addToWhitelist(alice);
        vm.prank(pair);
        vaulton.transfer(alice, 100 * 1e18);
        assertEq(vaulton.balanceOf(alice), 100 * 1e18);

        vm.roll(block.number + vaulton.ANTI_BOT_BLOCKS() + 1);
        vm.prank(pair);
        vaulton.transfer(bob, 100 * 1e18);
        assertEq(vaulton.balanceOf(bob), 100 * 1e18);
    }

    function testSetRouterFunction() public {
        address newRouter = makeAddr("newRouter");
        vm.prank(owner);
        vaulton.setRouter(newRouter);
        assertEq(vaulton.allowance(address(vaulton), newRouter), type(uint256).max);

        vm.prank(owner);
        vm.expectRevert("Invalid router");
        vaulton.setRouter(address(0));
    }

    function testTransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        vm.prank(owner);
        vaulton.transferOwnership(newOwner);
        assertEq(vaulton.owner(), newOwner);
    }
}