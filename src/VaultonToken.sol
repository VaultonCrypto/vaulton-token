// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Vaulton Token - Revolutionary Buyback Mechanism
 * @author Vaulton Team
 * @notice First BSC token with 36% supply buyback control for mathematical price support
 * @dev Ultra-simplified contract with innovative buyback mechanism - NO COOLDOWN
 * 
 * Key Features:
 * - 50% initial burn (15M tokens)
 * - 36% buyback control (5.4M tokens)
 * - Zero taxes
 * - Mathematical deflation guaranteed
 * - No cooldown restrictions
 */

contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    
    uint256 public constant TOTAL_SUPPLY = 30_000_000 * 10**18;
    uint256 public constant INITIAL_BURN = 15_000_000 * 10**18;
    uint256 public constant BUYBACK_RESERVE = 5_400_000 * 10**18;
    uint256 public constant CEX_ALLOCATION = 2_700_000 * 10**18;
    uint256 public constant PRESALE_ALLOCATION = 3_300_000 * 10**18;
    uint256 public constant LIQUIDITY_ALLOCATION = 2_100_000 * 10**18;
    uint256 public constant FOUNDER_ALLOCATION = 1_500_000 * 10**18;

    uint256 public burnedTokens;
    uint256 public buybackTokensRemaining;
    uint256 public buybackBNBBalance;
    uint256 public totalBuybackCycles;
    
    IUniswapV2Router02 public immutable pancakeRouter;
    address public pancakePair;
    bool public tradingEnabled;
    uint32 public launchBlock;

    mapping(uint256 => BuybackCycle) public buybackHistory;
    
    struct BuybackCycle {
        uint256 tokensSold;
        uint256 bnbReceived;
        uint256 tokensBought;
        uint256 tokensBurned;
        uint256 timestamp;
    }

    event BuybackSale(uint256 indexed cycleId, uint256 tokensSold, uint256 bnbReceived, uint256 timestamp);
    event BuybackBurn(uint256 indexed cycleId, uint256 tokensBought, uint256 bnbUsed, uint256 newTotalBurned);
    event BurnProgressUpdated(uint256 burnedAmount, uint256 burnPercentage);
    event TradingEnabled(uint256 blockNumber);
    event PairSet(address indexed pair);

    constructor(address _pancakeRouter) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        
        pancakeRouter = IUniswapV2Router02(_pancakeRouter);

        _mint(address(this), TOTAL_SUPPLY);
        _burn(address(this), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        buybackTokensRemaining = BUYBACK_RESERVE;
        
        uint256 tokensForOwner = balanceOf(address(this)) - BUYBACK_RESERVE;
        _transfer(address(this), owner(), tokensForOwner);
        
        assert(balanceOf(address(this)) == BUYBACK_RESERVE);
        emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0) && to != address(0), "Zero address transfer");
        require(amount > 0, "Zero amount transfer");
        
        if (!tradingEnabled) {
            require(
                from == owner() || 
                to == owner() || 
                from == address(this) || 
                to == address(this), 
                "Trading not enabled"
            );
        }
        
        super._transfer(from, to, amount);
    }

    /**
     * @notice Sells buyback reserve tokens for BNB (Owner only) - NO COOLDOWN
     * @param amount Number of tokens to sell (max 0.5% of total supply per transaction)
     */
    function sellBuybackTokens(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(amount <= buybackTokensRemaining, "Insufficient buyback reserve");
        require(amount <= (TOTAL_SUPPLY / 200), "Max 0.5% per transaction");
        require(pancakePair != address(0), "Trading pair not set");
        
        buybackTokensRemaining -= amount;
        totalBuybackCycles++;
        
        uint256 initialBNB = address(this).balance;
        _swapTokensForBNB(amount);
        uint256 bnbReceived = address(this).balance - initialBNB;
        buybackBNBBalance += bnbReceived;
        
        buybackHistory[totalBuybackCycles] = BuybackCycle({
            tokensSold: amount,
            bnbReceived: bnbReceived,
            tokensBought: 0,
            tokensBurned: 0,
            timestamp: block.timestamp
        });
        
        emit BuybackSale(totalBuybackCycles, amount, bnbReceived, block.timestamp);
    }

    /**
     * @notice Uses accumulated BNB to buyback and burn tokens (Owner only)
     */
    function buybackAndBurn() external onlyOwner nonReentrant {
        require(buybackBNBBalance > 0, "No BNB available for buyback");
        require(pancakePair != address(0), "Trading pair not set");
        require(totalBuybackCycles > 0, "No active buyback cycle");
        
        uint256 bnbAmount = buybackBNBBalance;
        buybackBNBBalance = 0;
        
        uint256 tokensBought = _swapBNBForTokens(bnbAmount);
        
        if (tokensBought > 0) {
            _burn(address(this), tokensBought);
            burnedTokens += tokensBought;
            
            buybackHistory[totalBuybackCycles].tokensBought = tokensBought;
            buybackHistory[totalBuybackCycles].tokensBurned = tokensBought;
            
            emit BuybackBurn(totalBuybackCycles, tokensBought, bnbAmount, burnedTokens);
            emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
        } else {
            buybackBNBBalance = bnbAmount;
            revert("Buyback failed");
        }
    }

    function _swapTokensForBNB(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function _swapBNBForTokens(uint256 bnbAmount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        uint256 balanceBefore = balanceOf(address(this));

        address tempWallet = address(uint160(uint256(keccak256(
            abi.encodePacked(block.timestamp, totalBuybackCycles, bnbAmount)
        ))));

        require(balanceOf(tempWallet) == 0, "Collision detected");

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0,
            path,
            tempWallet,
            block.timestamp + 300
        );

        uint256 tokensReceived = balanceOf(tempWallet);
        
        if (tokensReceived > 0) {
            super._transfer(tempWallet, address(this), tokensReceived);
        }

        return balanceOf(address(this)) - balanceBefore;
    }

    /**
     * @notice Enables trading for the token (One-time only)
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        launchBlock = uint32(block.number);
        emit TradingEnabled(block.number);
    }

    /**
     * @notice Sets the PancakeSwap trading pair (One-time only)
     * @param _pair Address of the VAULTON/WBNB pair contract
     */
    function setPancakePair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair address");
        require(pancakePair == address(0), "Pair already set");
        
        address factory = pancakeRouter.factory();
        address expectedPair = IUniswapV2Factory(factory).getPair(address(this), pancakeRouter.WETH());
        require(_pair == expectedPair, "Invalid pair contract");
        
        pancakePair = _pair;
        emit PairSet(_pair);
    }

    /**
     * @notice Returns complete tokenomics breakdown
     */
    function getTokenomics() external view returns (
        uint256 totalSupply,
        uint256 circulatingSupply,
        uint256 burnedTokens_,
        uint256 buybackReserve,
        uint256 founderAllocation,
        uint256 communityAllocation
    ) {
        uint256 communityTokens = PRESALE_ALLOCATION + LIQUIDITY_ALLOCATION + CEX_ALLOCATION;
        return (
            TOTAL_SUPPLY,
            TOTAL_SUPPLY - burnedTokens,
            burnedTokens,
            buybackTokensRemaining,
            FOUNDER_ALLOCATION,
            communityTokens
        );
    }

    /**
     * @notice Returns comprehensive buyback mechanism statistics
     */
    function getBuybackStats() external view returns (
        uint256 tokensRemaining,
        uint256 tokensUsed,
        uint256 bnbBalance,
        uint256 totalBurned,
        uint256 controlPercentage,
        uint256 cyclesCompleted,
        bool nextCycleReady
    ) {
        uint256 circulatingSupply = TOTAL_SUPPLY - burnedTokens;
        return (
            buybackTokensRemaining,
            BUYBACK_RESERVE - buybackTokensRemaining,
            buybackBNBBalance,
            burnedTokens,
            buybackTokensRemaining > 0 ? (buybackTokensRemaining * 100) / circulatingSupply : 0,
            totalBuybackCycles,
            buybackBNBBalance > 0
        );
    }

    /**
     * @notice Returns detailed information about a specific buyback cycle
     */
    function getBuybackCycle(uint256 cycleId) external view returns (
        uint256 tokensSold,
        uint256 bnbReceived,
        uint256 tokensBought,
        uint256 tokensBurned,
        uint256 timestamp,
        bool completed
    ) {
        require(cycleId > 0 && cycleId <= totalBuybackCycles, "Invalid cycle ID");
        
        BuybackCycle memory cycle = buybackHistory[cycleId];
        return (
            cycle.tokensSold,
            cycle.bnbReceived,
            cycle.tokensBought,
            cycle.tokensBurned,
            cycle.timestamp,
            cycle.tokensBought > 0
        );
    }

    /**
     * @notice Returns security and control metrics for transparency
     */
    function getSecurityStatus() external view returns (
        uint256 buybackControlPercentage,
        bool tradingActive,
        bool pairSet,
        uint256 contractBalance,
        uint256 communityControl
    ) {
        uint256 circulatingSupply = TOTAL_SUPPLY - burnedTokens;
        uint256 communityTokens = PRESALE_ALLOCATION + LIQUIDITY_ALLOCATION + CEX_ALLOCATION;
        return (
            (buybackTokensRemaining * 100) / circulatingSupply,
            tradingEnabled,
            pancakePair != address(0),
            balanceOf(address(this)),
            (communityTokens * 100) / TOTAL_SUPPLY
        );
    }

    /**
     * @notice Returns essential metrics for quick dashboard display
     */
    function getQuickStats() external view returns (
        uint256 burnProgress,
        uint256 buybackPower,
        uint256 circulatingSupply,
        bool trading
    ) {
        uint256 circulating = TOTAL_SUPPLY - burnedTokens;
        
        return (
            (burnedTokens * 100) / TOTAL_SUPPLY,
            buybackTokensRemaining > 0 ? (buybackTokensRemaining * 100) / circulating : 0,
            circulating,
            tradingEnabled
        );
    }

    /**
     * @notice Standard ownership renunciation (PinkSale compatible)
     * @dev Allows owner to renounce ownership at any time - Standard OpenZeppelin behavior
     */
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    /**
     * @notice Transfer ownership with validation
     * @dev PinkSale compatible: Allows ownership transfer but prevents zero address
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != address(this), "New owner cannot be contract");
        super.transferOwnership(newOwner);
    }

    /**
     * @notice Returns contract owner (PinkSale compatibility) 
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice Returns if contract has taxes (PinkSale compatibility)
     */
    function hasTax() external pure returns (bool) {
        return false;
    }

    /**
     * @notice Returns if contract is renounced (PinkSale compatibility)
     */
    function isRenounced() external view returns (bool) {
        return owner() == address(0);
    }

    /**
     * @notice Returns if contract has mint function (PinkSale compatibility)
     */
    function hasMintFunction() external pure returns (bool) {
        return false;
    }

    /**
     * @notice Returns if contract has burn function (PinkSale compatibility)
     */
    function hasBurnFunction() external pure returns (bool) {
        return true;
    }

    receive() external payable {}
}
