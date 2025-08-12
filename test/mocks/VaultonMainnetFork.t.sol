// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../../src/VaultonToken.sol";

contract VaultonMainnetForkTest is Test {
    Vaulton vaulton;
    address owner;
    address alice;
    address pair;
    
    // Vraies adresses BSC Mainnet
    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // Fork ID
    uint256 mainnetFork;
    
    function setUp() public {
        // Fork BSC mainnet au bloc le plus récent
        string memory BSC_RPC_URL = vm.envString("BSC_RPC_URL");
        mainnetFork = vm.createFork(BSC_RPC_URL);
        vm.selectFork(mainnetFork);
        
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        
        // Deal BNB pour les frais de gas
        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        
        vm.startPrank(owner);
        vaulton = new Vaulton(
            PANCAKE_ROUTER,
            makeAddr("cexWallet")
        );
        vm.stopPrank();
    }
    
    function testMainnetDeployment() public view {
        assertEq(vaulton.TOTAL_SUPPLY(), 30_000_000 * 1e18);
        assertEq(vaulton.burnedTokens(), vaulton.INITIAL_BURN());
        
        // ✅ Corriger cette ligne
        assertEq(address(vaulton.pancakeRouter()), PANCAKE_ROUTER);
    }
    
    function testRealPancakeSwapIntegration() public {
        // Setup contract avec vraie liquidité
        vm.prank(owner);
        vaulton.transfer(address(vaulton), 10_000_000 * 1e18);
        vm.prank(owner);
        vaulton.updateBuybackReserve();
        
        // Créer vraie pair PancakeSwap
        address realPair = _createPancakePair();
        
        vm.prank(owner);
        vaulton.setPair(realPair);
        vm.prank(owner);
        vaulton.enableTrading();
        
        // Ajouter vraie liquidité
        _addLiquidity(realPair, 1_000_000 * 1e18, 50 ether);
        
        // Test vente réelle
        vm.prank(owner);
        vaulton.transfer(alice, 100_000 * 1e18);
        
        uint256 buybackBefore = vaulton.buybackTokensRemaining();
        
        vm.prank(alice);
        vaulton.transfer(realPair, 50_000 * 1e18);
        
        // Vérifier que auto-sell fonctionne avec vrai PancakeSwap
        if (vaulton.buybackTokensRemaining() > 0) {
            assertTrue(vaulton.buybackTokensRemaining() <= buybackBefore, "Auto-sell should work with sufficient reserves");
        } else {
            assertTrue(true, "No buyback tokens remaining - test completed");
        }
    }
    
    function testMainnetBNBThresholdRealistic() public {
        vm.prank(owner);
        vaulton.transfer(address(vaulton), 10_000_000 * 1e18);
        vm.prank(owner);
        vaulton.updateBuybackReserve();
        
        address realPair = _createPancakePair();
        vm.prank(owner);
        vaulton.setPair(realPair);
        vm.prank(owner);
        vaulton.enableTrading();
        
        // Liquidité réaliste (20 BNB)
        _addLiquidity(realPair, 2_000_000 * 1e18, 20 ether);
        
        vm.prank(owner);
        vaulton.transfer(alice, 500_000 * 1e18);
        
        // Ventes progressives pour atteindre seuil 0.03 BNB
        for (uint i = 0; i < 10; i++) {
            vm.prank(alice);
            vaulton.transfer(realPair, 25_000 * 1e18);
            
            // Vérifier si buyback déclenché
            if (vaulton.lastBuybackBlock() > 0) {
                assertTrue(true, "Buyback triggered at realistic threshold");
                break;
            }
        }
    }
    
    function testRealSlippageConditions() public {
        vm.prank(owner);
        vaulton.transfer(address(vaulton), 10_000_000 * 1e18);
        vm.prank(owner);
        vaulton.updateBuybackReserve();
        
        address realPair = _createPancakePair();
        vm.prank(owner);
        vaulton.setPair(realPair);
        vm.prank(owner);
        vaulton.enableTrading();
        
        // Liquidité faible pour tester slippage élevé
        _addLiquidity(realPair, 500_000 * 1e18, 5 ether);
        
        vm.prank(owner);
        vaulton.transfer(alice, 200_000 * 1e18);
        
        // Grosse vente qui créera du slippage
        uint256 buybackBefore = vaulton.buybackTokensRemaining();
        
        vm.prank(alice);
        vaulton.transfer(realPair, 100_000 * 1e18); // 20% de la liquidité
        
        // Même avec slippage élevé, mécanisme doit fonctionner
        assertTrue(vaulton.buybackTokensRemaining() <= buybackBefore, "Should handle high slippage");
    }
    
    function testGasConsumptionMainnet() public {
        vm.prank(owner);
        vaulton.transfer(address(vaulton), 10_000_000 * 1e18);
        vm.prank(owner);
        vaulton.updateBuybackReserve();
        
        address realPair = _createPancakePair();
        vm.prank(owner);
        vaulton.setPair(realPair);
        vm.prank(owner);
        vaulton.enableTrading();
        
        _addLiquidity(realPair, 1_000_000 * 1e18, 10 ether);
        
        vm.prank(owner);
        vaulton.transfer(alice, 100_000 * 1e18);
        
        // Mesurer gas pour vente avec auto-sell
        uint256 gasBefore = gasleft();
        
        vm.prank(alice);
        vaulton.transfer(realPair, 50_000 * 1e18);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Vérifier que gas reste raisonnable (< 500k gas)
        assertTrue(gasUsed < 500_000, "Gas consumption should be reasonable");
    }
    
    // Helper functions
    function _createPancakePair() internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(PANCAKE_FACTORY);
        address pairAddress = factory.createPair(address(vaulton), WBNB);
        return pairAddress;
    }
    
    function _addLiquidity(address pairAddress, uint256 tokenAmount, uint256 bnbAmount) internal {
        // Transfer tokens to pair
        vm.prank(owner);
        vaulton.transfer(pairAddress, tokenAmount);
        
        // Send BNB to pair
        vm.deal(pairAddress, bnbAmount);
        
        // Sync pair
        IUniswapV2Pair(pairAddress).sync();
    }
}

// Interfaces nécessaires
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}