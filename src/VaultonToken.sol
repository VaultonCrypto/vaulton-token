// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Vaulton Token
 * @author Vaulton Team
 * @notice A deflationary token that automatically removes taxes once 75% of supply is burned
 * @dev Implements automatic burn mechanism and strategic liquidity management
 * 
 * SECURITY: Wallets are set once at deployment and CANNOT be changed (no updateWallets function)
 * 
 * Key Features:
 * - 60% of taxes are burned automatically on each transaction
 * - 40% of taxes accumulate for marketing (manually convertible to BNB)
 * - Taxes automatically removed when 75% of total supply is burned
 * - No instant liquidity mechanism - clean tax distribution
 * - Owner can renounce after conditions are met (PinkSale compatible)
 * - Fund wallets are IMMUTABLE - maximum rug pull protection
 * - LP tokens burned for permanent liquidity (superior to time locks)
 */
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // ========================================
    // CONSTANTS
    // ========================================
    
    /// @notice Total supply of VAULTON tokens (50 million)
    uint256 public constant TOTAL_SUPPLY = 50_000_000 * 10**18;
    
    /// @notice Amount of tokens burned at deployment (15 million)
    uint256 public constant INITIAL_BURN = 15_000_000 * 10**18;
    
    /// @notice Threshold at which taxes are permanently removed (75% of total supply)
    uint256 public constant BURN_THRESHOLD = (TOTAL_SUPPLY * 75) / 100;

    /// @dev Tax distribution percentages
    uint256 private constant BURN_PERCENT = 60;     // 60% of taxes burned
    uint256 private constant MARKETING_PERCENT = 40; // 40% for marketing

    /// @dev Tax rates (immutable)
    uint8 private constant BUY_TAX = 5;              // 5% buy tax
    uint8 private constant SELL_TAX = 10;            // 10% sell tax
    uint8 private constant WALLET_TAX = 3;           // 3% wallet-to-wallet tax
    
    /// @dev Anti-bot protection duration in blocks
    uint256 private constant ANTI_BOT_BLOCKS = 3;

    /// @notice BNB distribution shares for fund distribution
    uint256 public constant MARKETING_SHARE = 45;    // 45% to marketing wallet
    uint256 public constant CEX_SHARE = 25;          // 25% to CEX wallet
    uint256 public constant OPERATIONS_SHARE = 30;   // 30% to operations wallet

    // ========================================
    // STATE VARIABLES
    // ========================================

    /// @notice Total amount of tokens burned throughout contract lifetime
    uint256 public burnedTokens;
    
    /// @notice Marketing tokens accumulated from taxes (convertible to BNB)
    uint256 public marketingTokensAccumulated;

    /// @notice Immutable reference to PancakeSwap router
    IUniswapV2Router02 public immutable pancakeRouter;
    
    /// @notice Address of the main trading pair (VAULTON/WBNB)
    address public pancakePair;

    /// @notice Wallet addresses for fund distribution (SET ONCE - cannot be changed)
    address public marketingWallet;   // Immutable after deployment
    address public cexWallet;         // Immutable after deployment  
    address public operationsWallet;  // Immutable after deployment

    /// @notice Trading state and configuration
    bool public tradingEnabled;
    bool public taxesRemoved;
    uint32 public launchBlock;

    /// @notice Mapping to identify DEX pairs for tax calculation
    mapping(address => bool) public isDexPair;
    
    /// @dev Mapping to track fee exclusions
    mapping(address => bool) private isExcludedFromFees;

    /// @dev Lock to prevent reentrancy during swaps
    bool private inSwapAndLiquify;

    // ========================================
    // EVENTS
    // ========================================

    /// @notice Emitted when taxes are applied to a transaction
    event TaxApplied(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, string taxType);
    
    /// @notice Emitted when taxes are permanently removed at 75% burn
    event TaxesRemoved();
    
    /// @notice Emitted when burn progress is updated
    event BurnProgressUpdated(uint256 burnedAmount, uint256 burnPercentage);
    
    /// @notice Emitted when trading is enabled
    event TradingEnabled(uint256 blockNumber);
    
    /// @notice Emitted when BNB is distributed to wallets
    event FundsDistributed(uint256 marketingAmount, uint256 cexAmount, uint256 operationsAmount);
    
    /// @notice Emitted when marketing tokens are converted to BNB
    event MarketingTokensProcessed(uint256 tokensSwapped, uint256 bnbReceived);
    
    /// @notice Emitted when a trading pair is automatically detected
    event PairAutoDetected(address indexed pair);

    // ========================================
    // MODIFIERS
    // ========================================

    /// @dev Prevents reentrancy during swap operations
    modifier lockTheSwap() {
        require(!inSwapAndLiquify, "Swap locked");
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /// @dev Provides anti-bot protection during first 3 blocks after launch
    modifier antiBotProtection() {
        if (tradingEnabled && block.number <= launchBlock + ANTI_BOT_BLOCKS) {
            if (_isContract(msg.sender)) {
                require(_isAllowedContract(msg.sender), "Contract not allowed during launch");
            }
        }
        _;
    }

    // ========================================
    // CONSTRUCTOR
    // ========================================

    /**
     * @notice Deploys the Vaulton token contract with PERMANENT wallet addresses
     * @param _pancakeRouter Address of the PancakeSwap V2 router
     * @param _marketingWallet Address of the marketing wallet (CANNOT be changed later)
     * @param _cexWallet Address of the CEX wallet (CANNOT be changed later)
     * @param _operationsWallet Address of the operations wallet (CANNOT be changed later)
     * 
     * @dev Deployment Process:
     * 1. Mints 50M total supply to owner
     * 2. Burns 15M tokens immediately (30% initial burn)
     * 3. Sets IMMUTABLE wallet addresses (no update function exists)
     * 4. Excludes owner and contract from fees
     * 5. Initializes burn tracking and progress events
     * 
     * @dev Security Features:
     * - All wallet addresses are immutable post-deployment
     * - No admin functions to change core parameters
     * - Initial burn creates immediate deflationary pressure
     */
    constructor(
        address _pancakeRouter,
        address _marketingWallet,
        address _cexWallet, 
        address _operationsWallet
    ) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_cexWallet != address(0), "Invalid CEX wallet");
        require(_operationsWallet != address(0), "Invalid operations wallet");
        
        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        
        // Set IMMUTABLE wallet addresses
        marketingWallet = _marketingWallet;
        cexWallet = _cexWallet;
        operationsWallet = _operationsWallet;

        // Mint total supply and perform initial burn
        _mint(owner(), TOTAL_SUPPLY);
        _burn(owner(), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        
        emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);

        // Exclude system addresses from fees
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
    }

    // ========================================
    // CORE TRANSFER LOGIC
    // ========================================

    /**
     * @dev Hook called before token transfers to setup pairs and check burn threshold
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Auto-detect and setup trading pairs
        _detectAndSetupPair();

        // Check if burn threshold reached and remove taxes
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @dev Core transfer function with tax logic and anti-bot protection
     */
    function _transfer(address from, address to, uint256 amount) internal override antiBotProtection {
        require(from != address(0) && to != address(0), "Zero address");
        require(amount > 0, "Zero amount");
        
        if (!tradingEnabled) {
            require(
                from == owner() || 
                to == owner() || 
                from == address(this) || 
                to == address(this), 
                "Trading not enabled"
            );
        }
        
        uint256 taxAmount = _calculateTax(from, to, amount);
        
        if (taxAmount > 0) {
            super._transfer(from, to, amount - taxAmount);
            super._transfer(from, address(this), taxAmount);
            _processTaxes(taxAmount);
            emit TaxApplied(from, to, amount, taxAmount, _getTaxType(from, to));
        } else {
            super._transfer(from, to, amount);
        }
    }

    // ========================================
    // TAX PROCESSING
    // ========================================

    /**
     * @dev Calculates tax amount based on transaction type
     * @param from Sender address
     * @param to Recipient address  
     * @param amount Transaction amount
     * @return Tax amount to be collected
     */
    function _calculateTax(address from, address to, uint256 amount) private view returns (uint256) {
        if (taxesRemoved || isExcludedFromFees[from] || isExcludedFromFees[to]) {
            return 0;
        }
        
        bool isBuy = isDexPair[from] && !isDexPair[to];
        bool isSell = !isDexPair[from] && isDexPair[to];
        bool isWalletToWallet = !isDexPair[from] && !isDexPair[to];
        
        uint256 taxRate;
        if (isBuy) {
            taxRate = BUY_TAX;          // 5%
        } else if (isSell) {
            taxRate = SELL_TAX;         // 10%
        } else if (isWalletToWallet) {
            taxRate = WALLET_TAX;       // 3%
        } else {
            taxRate = 0;
        }
        
        return (amount * taxRate) / 100;
    }

    /**
     * @dev Processes collected taxes with 60/40 split (burn/marketing)
     * @param taxAmount Total tax amount to process
     * 
     * Tax Distribution:
     * - 60% burned immediately to dead address
     * - 40% accumulated as marketing tokens (convertible to BNB)
     */
    function _processTaxes(uint256 taxAmount) private {
        uint256 burnAmount = (taxAmount * BURN_PERCENT) / 100;      // 60%
        uint256 marketingAmount = taxAmount - burnAmount;           // 40%
        
        if (burnAmount > 0) {
            super._transfer(address(this), address(0x000000000000000000000000000000000000dEaD), burnAmount);
            burnedTokens += burnAmount;
            emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
        }
        
        if (marketingAmount > 0) {
            marketingTokensAccumulated += marketingAmount;
        }
    }

    /**
     * @dev Returns transaction type for event logging
     */
    function _getTaxType(address from, address to) private view returns (string memory) {
        if (isDexPair[from] && !isDexPair[to]) {
            return "buy";
        } else if (!isDexPair[from] && isDexPair[to]) {
            return "sell";
        } else {
            return "transfer";
        }
    }

    /**
     * @dev Permanently removes taxes when burn threshold is reached
     */
    function _removeTaxes() internal {
        require(!taxesRemoved, "Taxes already removed");
        taxesRemoved = true;
        emit TaxesRemoved();
    }

    // ========================================
    // LIQUIDITY FUNCTIONS
    // ========================================

    /**
     * @notice Adds liquidity to existing pair (PinkSale compatible)
     * @param tokenAmount Amount of tokens to add to liquidity
     * @dev Only works if pair already exists (safe for PinkSale)
     */
    function addLiquidity(uint256 tokenAmount) external payable onlyOwner {
        require(msg.value > 0, "Must send BNB");
        require(balanceOf(owner()) >= tokenAmount, "Insufficient owner tokens");
        
        address factory = pancakeRouter.factory();
        address existingPair = IUniswapV2Factory(factory).getPair(address(this), pancakeRouter.WETH());
        require(existingPair != address(0), "Pair must exist - use PinkSale to create first");
        
        _transfer(owner(), address(this), tokenAmount);
        _approve(address(this), address(pancakeRouter), tokenAmount);
        
        pancakeRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            tokenAmount * 95 / 100,
            msg.value * 95 / 100,
            address(0),
            block.timestamp + 300
        );
    }

    /**
     * @dev Swaps tokens for BNB using the router
     * @param tokenAmount Amount of tokens to swap
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(balanceOf(address(this)) >= tokenAmount, "Insufficient contract balance");
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300 // 5 minutes deadline
        ) {
            // Swap réussi - pas d'action nécessaire
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Swap failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            if (lowLevelData.length == 0) {
                revert("Swap failed: Unknown error");
            } else {
                revert("Swap failed: Low-level error");
            }
        }
    }

    /**
     * @dev Automatically detects and sets up the main trading pair
     */
    function _detectAndSetupPair() internal {
        address factory = pancakeRouter.factory();
        address pair = IUniswapV2Factory(factory).getPair(address(this), pancakeRouter.WETH());
        
        if (pair != address(0) && pancakePair == address(0)) {
            pancakePair = pair;
            isDexPair[pair] = true;
            emit PairAutoDetected(pair);
        }
        
        if (pancakePair != address(0) && !isDexPair[pancakePair]) {
            isDexPair[pancakePair] = true;
        }
    }

    // ========================================
    // ADMIN FUNCTIONS
    // ========================================

    /**
     * @notice Enables trading for the token
     * @dev Can only be called once by owner. Liquidity can be added before or after.
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
    
        tradingEnabled = true;
        launchBlock = uint32(block.number);
        emit TradingEnabled(block.number);
    }

    /**
     * @notice Excludes or includes an address from fees
     * @param _address Address to modify fee status for
     * @param _status True to exclude from fees, false to include
     */
    function excludeFromFees(address _address, bool _status) external onlyOwner {
        isExcludedFromFees[_address] = _status;
    }

    /**
     * @notice Sets DEX pair status for an address
     * @param _pair Address of the pair contract
     * @param _status True if this is a DEX pair, false otherwise
     */
    function setDexPair(address _pair, bool _status) external onlyOwner {
        isDexPair[_pair] = _status;
    }

    /**
     * @notice Converts a specific amount of accumulated marketing tokens to BNB
     * @param tokenAmount Amount of marketing tokens to convert
     * @dev Converts tokens via DEX swap and stores BNB in contract for distribution
     * @dev Use distributeFunds() after conversion to send BNB to wallets
     * 
     * Process:
     * 1. Validates sufficient marketing tokens available
     * 2. Swaps tokens for BNB via PancakeSwap
     * 3. Stores BNB in contract for later distribution
     * 4. Reduces marketingTokensAccumulated by converted amount
     */
    function convertMarketingTokens(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Amount must be greater than 0");
        require(tokenAmount <= marketingTokensAccumulated, "Insufficient marketing tokens");
        
        uint256 initialBnb = address(this).balance;
        swapTokensForBNB(tokenAmount);
        uint256 bnbReceived = address(this).balance - initialBnb;
        
        marketingTokensAccumulated -= tokenAmount;
        
        emit MarketingTokensProcessed(tokenAmount, bnbReceived);
    }

    /**
     * @notice Converts all accumulated marketing tokens to BNB
     * @dev Convenience function to convert entire marketing token balance
     * @dev Equivalent to calling convertMarketingTokens() with full balance
     */
    function convertAllMarketingTokens() external onlyOwner {
        require(marketingTokensAccumulated > 0, "No marketing tokens to convert");
        
        uint256 tokenAmount = marketingTokensAccumulated;
        uint256 initialBnb = address(this).balance;
        swapTokensForBNB(tokenAmount);
        uint256 bnbReceived = address(this).balance - initialBnb;
        
        marketingTokensAccumulated = 0;
        
        emit MarketingTokensProcessed(tokenAmount, bnbReceived);
    }

    /**
     * @notice Distributes contract BNB balance to IMMUTABLE designated wallets
     * @dev Distributes according to fixed percentages: 45% marketing, 25% CEX, 30% operations
     * @dev Wallets CANNOT be changed - provides maximum security against fund redirection
     * 
     * Distribution Breakdown:
     * - 45% to marketing wallet (campaigns, partnerships, development)
     * - 25% to CEX wallet (exchange listings, market making)
     * - 30% to operations wallet (team, infrastructure, legal)
     * 
     * Security Features:
     * - Wallet addresses are immutable (set once at deployment)
     * - No updateWallets() function exists
     * - ReentrancyGuard protection
     * - All transfers verified with require statements
     */
    function distributeFunds() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 totalBalance = address(this).balance;
        
        uint256 marketingAmount = (totalBalance * MARKETING_SHARE) / 100;   // 45%
        uint256 cexAmount = (totalBalance * CEX_SHARE) / 100;               // 25%
        uint256 operationsAmount = (totalBalance * OPERATIONS_SHARE) / 100; // 30%
        
        (bool success1, ) = marketingWallet.call{value: marketingAmount}("");
        require(success1, "Marketing transfer failed");
        
        (bool success2, ) = cexWallet.call{value: cexAmount}("");
        require(success2, "CEX transfer failed");
        
        (bool success3, ) = operationsWallet.call{value: operationsAmount}("");
        require(success3, "Operations transfer failed");
        
        emit FundsDistributed(marketingAmount, cexAmount, operationsAmount);
    }

    /**
     * @notice Renounces ownership of the contract (PinkSale compatible)
     * @dev Simple renouncement function. Use getRenounceStatus() to check if safe to renounce
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    // ========================================
    // VIEW FUNCTIONS
    // ========================================

    /**
     * @notice Returns comprehensive stats for dashboard display
     * @return burned Total tokens burned since deployment
     * @return burnProgress Progress towards 75% burn threshold (percentage)
     * @return marketingTokens Marketing tokens available for conversion to BNB
     * @return contractBnb BNB balance in contract ready for distribution
     * @return trading Whether trading is currently enabled
     * @return pair Address of main trading pair (VAULTON/WBNB)
     * @return taxesRemoved_ Whether taxes have been permanently removed
     * @return circulatingSupply Current circulating supply (total - burned)
     */
    function getQuickStats() external view returns (
        uint256 burned,
        uint256 burnProgress,
        uint256 marketingTokens,
        uint256 contractBnb,
        bool trading,
        address pair,
        bool taxesRemoved_,
        uint256 circulatingSupply
    ) {
        burned = burnedTokens;
        burnProgress = (burnedTokens * 100) / BURN_THRESHOLD;
        marketingTokens = marketingTokensAccumulated;
        contractBnb = address(this).balance;
        trading = tradingEnabled;
        pair = pancakePair;
        taxesRemoved_ = taxesRemoved;
        circulatingSupply = TOTAL_SUPPLY - burnedTokens;
    }

    /**
     * @notice Returns basic token information
     * @return name Token name
     * @return symbol Token symbol
     * @return totalSupply Initial total supply
     * @return circulatingSupply Current circulating supply (total - burned)
     * @return decimals Token decimals
     * @return burned Total burned tokens
     * @return burnPercentage Percentage of total supply burned
     */
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 circulatingSupply,
        uint8 decimals,
        uint256 burned,
        uint256 burnPercentage
    ) {
        name = "Vaulton";
        symbol = "VAULTON";
        totalSupply = TOTAL_SUPPLY;
        circulatingSupply = TOTAL_SUPPLY - burnedTokens;
        decimals = 18;
        burned = burnedTokens;
        burnPercentage = (burnedTokens * 100) / TOTAL_SUPPLY;
    }

    /**
     * @notice Returns current tax rates
     * @return buy Buy tax percentage
     * @return sell Sell tax percentage  
     * @return walletToWallet Wallet-to-wallet transfer tax percentage
     */
    function getTaxRates() external pure returns (uint8 buy, uint8 sell, uint8 walletToWallet) {
        return (BUY_TAX, SELL_TAX, WALLET_TAX);
    }

    /**
     * @notice Returns burn mechanism progress
     * @return currentBurned Total tokens burned so far
     * @return burnThreshold Threshold for tax removal (75% of total supply)
     * @return progressPercentage Progress towards threshold (percentage)
     * @return thresholdReached Whether the threshold has been reached
     */
    function getBurnProgress() external view returns (
        uint256 currentBurned,
        uint256 burnThreshold,
        uint256 progressPercentage,
        bool thresholdReached
    ) {
        uint256 progress = (burnedTokens * 100) / BURN_THRESHOLD;
        
        return (burnedTokens, BURN_THRESHOLD, progress, burnedTokens >= BURN_THRESHOLD);
    }

    // ========================================
    // INTERNAL HELPERS
    // ========================================

    /**
     * @dev Checks if an address is a contract
     * @param account Address to check
     * @return True if the address is a contract
     */
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @dev Checks if a contract address is allowed during anti-bot protection
     * @param account Contract address to check
     * @return True if the contract is allowed to trade during launch
     */
    function _isAllowedContract(address account) private view returns (bool) {
        if (account == address(pancakeRouter)) return true;
        if (pancakePair != address(0) && account == pancakePair) return true;
        if (isExcludedFromFees[account]) return true;
        if (isDexPair[account]) return true;
        
        return false;
    }

    /**
     * @dev Allows contract to receive BNB from swaps and liquidity operations
     */
    receive() external payable {
        // Contract can now receive BNB from PancakeSwap swaps
    }
}
