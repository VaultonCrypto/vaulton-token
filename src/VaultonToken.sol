// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Vaulton Token
 * @dev Implementation of the Vaulton Token with burn mechanism, taxes, and BNB distribution
 * @author Vaulton Team
 * @notice This token implements a burn mechanism that removes taxes once 75% of supply is burned
 */
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // Constants
    /// @notice Total supply of VAULTON tokens (50 million)
    /// @dev This is the maximum amount of tokens that will ever exist
    uint256 public constant TOTAL_SUPPLY = 50_000_000 * 10**18;

    /// @notice Amount of tokens burned at contract deployment (15 million)
    /// @dev This represents 30% of total supply burned immediately upon launch
    uint256 public constant INITIAL_BURN = 15_000_000 * 10**18;

    /// @notice Threshold at which taxes are automatically and permanently removed
    /// @dev Set to 75% of total supply (37.5 million tokens including initial burn)
    /// @dev Once reached, buyTax and sellTax are set to 0% forever
    uint256 public constant BURN_THRESHOLD = (TOTAL_SUPPLY * 75) / 100;

    /// @notice Maximum amount allowed in a single transaction (1% of total supply)
    /// @dev Applies to transfers between wallets (not DEX operations)
    /// @dev Prevents whale manipulation while allowing normal trading
    uint256 public constant MAX_TX_AMOUNT = TOTAL_SUPPLY / 100;

    // State variables

    /// @notice Total amount of tokens burned throughout the contract's lifetime
    /// @dev This counter is used to track progress toward the 75% burn threshold
    /// @dev When BURN_THRESHOLD is reached, all taxes are permanently disabled
    uint256 public burnedTokens;

    /// @notice Interface to the PancakeSwap V2 router for token swaps and liquidity operations
    /// @dev Used for converting accumulated tokens to BNB and adding liquidity
    IUniswapV2Router02 public pancakeRouter;

    /// @notice Address of the main trading pair (typically VAULTON/WBNB)
    /// @dev This pair is used for buy/sell tax calculations and swap operations
    /// @dev Set via setPancakePair() after launch or auto-detected via _detectAndSetupPair()
    address public pancakePair;

    // Wallets
    address public marketingWallet;
    address public cexWallet;
    address public operationsWallet;

    // Shares for distribution (total = 100%)
    uint256 public marketingShare = 45;
    uint256 public cexShare = 25;
    uint256 public operationsShare = 30;

    // Distribution queue
    mapping(address => uint256) public pendingDistributions;
    bool private distributionQueued;
    uint256 private lastDistributionBlock;
    uint256 private constant DISTRIBUTION_DELAY = 1;

    // Mappings
    mapping(address => bool) public isDexPair;
    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) private isBlacklisted;
    bool private inSwapAndLiquify;
    bool public taxesRemoved;

    // Tax Constants
    uint256 public buyTax = 5;
    uint256 public sellTax = 10;

    /// @notice Percentage of each tax allocated to token burning (60%)
    /// @dev This is the primary deflationary mechanism of the token
    uint256 private constant BURN_PERCENT = 60;

    /// @notice Percentage of each tax allocated to marketing operations (25%)
    /// @dev These tokens are accumulated in contract and converted to BNB for distribution
    uint256 private constant MARKETING_PERCENT = 25;

    /// @notice Percentage of each tax allocated to liquidity provision (15%)
    /// @dev These tokens are automatically converted to BNB and added back to liquidity pool
    uint256 private constant LIQUIDITY_PERCENT = 15;

    /// @notice Maximum amount allowed in DEX-to-DEX transfers (0.5% of total supply)
    uint256 public maxDexToDexAmount = TOTAL_SUPPLY / 200;

    /// @notice Tracks last DEX-to-DEX transfer time for each address (cooldown mechanism)
    mapping(address => uint256) private lastDexToDexTime;

    /// @notice Cooldown period between DEX-to-DEX transfers (5 minutes)
    uint256 private constant DEX_TO_DEX_COOLDOWN = 300;

    /// @notice Whether automatic token swapping is enabled
    bool public swapEnabled = true;

    /**
     * @notice Emitted when tax is applied to a transaction
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Total amount of the transaction
     * @param taxAmount Amount of tax collected
     * @param taxType Type of tax applied (buy/sell/universal)
     */
    event TaxApplied(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, string taxType);
    
    /**
     * @notice Emitted when swap and liquify process completes
     * @param tokensSwapped Amount of tokens swapped for BNB
     * @param bnbReceived Amount of BNB received from swap
     * @param tokensIntoLiquidity Amount of tokens added to liquidity
     */
    event SwapAndLiquifyCompleted(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    
    /**
     * @notice Emitted when a DEX pair status is updated
     * @param pair Address of the DEX pair
     * @param status New status of the pair
     */
    event DexPairUpdated(address indexed pair, bool status);
    
    /**
     * @notice Emitted when taxes are removed after burn threshold is reached
     */
    event TaxesRemoved();
    
    /**
     * @notice Emitted when initial burn is completed
     * @param amount Amount of tokens burned initially
     * @param timestamp Time when the burn occurred
     */
    event InitialBurnCompleted(uint256 amount, uint256 timestamp);
    
    /**
     * @notice Emitted when a DEX pair is automatically detected
     * @param pair Address of the detected pair
     */
    event PairAutoDetected(address indexed pair);
    
    /**
     * @notice Emitted when burn progress is updated
     * @param burnedAmount Total amount burned
     * @param burnPercentage Percentage of total supply burned
     */
    event BurnProgressUpdated(uint256 burnedAmount, uint256 burnPercentage);
    
    /**
     * @notice Emitted when tax rates are updated
     * @param buyTax New buy tax percentage
     * @param sellTax New sell tax percentage
     */
    event TaxesUpdated(uint256 buyTax, uint256 sellTax);
    
    /**
     * @notice Emitted when max transaction amount is updated
     * @param maxTxAmount New maximum transaction amount
     */
    event MaxTransactionUpdated(uint256 maxTxAmount);
    
    /**
     * @notice Emitted when marketing contract is updated
     * @param oldContract Previous marketing contract address
     * @param newContract New marketing contract address
     */
    event MarketingContractUpdated(address indexed oldContract, address indexed newContract);
    
    /**
     * @notice Emitted when funds are distributed to wallets
     * @param marketingAmount Amount sent to marketing wallet
     * @param cexAmount Amount sent to CEX wallet
     * @param operationsAmount Amount sent to operations wallet
     */
    event FundsDistributed(uint256 marketingAmount, uint256 cexAmount, uint256 operationsAmount);
    
    /**
     * @notice Emitted when wallet addresses are updated
     * @param marketingWallet New marketing wallet address
     * @param cexWallet New CEX wallet address
     * @param operationsWallet New operations wallet address
     */
    event WalletsUpdated(address indexed marketingWallet, address indexed cexWallet, address indexed operationsWallet);
    
    /**
     * @notice Emitted when distribution shares are updated
     * @param marketingShare New marketing share percentage
     * @param cexShare New CEX share percentage
     * @param operationsShare New operations share percentage
     */
    event SharesUpdated(uint256 marketingShare, uint256 cexShare, uint256 operationsShare);

    /**
     * @notice Emitted when swap enabled status is updated
     * @param enabled New swap enabled status
     */
    event SwapEnabledUpdated(bool enabled);

    /**
     * @notice Prevents reentrancy attacks during swap and liquify operations
     * @dev Sets inSwapAndLiquify flag to prevent recursive calls to swap functions
     */
    modifier lockTheSwap() {
        require(!inSwapAndLiquify, "Swap locked");
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * @notice Automatically detects trading pair before executing function
     * @dev Ensures pair configuration is up-to-date before tax calculations
     */
    modifier detectPair() {
        _detectAndSetupPair();
        _;
    }

    /**
     * @notice Contract constructor initializes the token and sets up initial configuration
     * @dev Initializes wallets with owner address, which should be updated post-deployment
     * @param _pancakeRouter Address of the PancakeSwap router
     */
    constructor(
        address _pancakeRouter
    ) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");

        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        
        // Initialize wallets with owner address - must be updated after deployment
        // via updateWallets() with appropriate dedicated addresses
        marketingWallet = owner();
        cexWallet = owner();
        operationsWallet = owner();

        // Mint total supply to owner
        _mint(owner(), TOTAL_SUPPLY);
        
        // Initial burn
        _burn(owner(), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        
        emit InitialBurnCompleted(INITIAL_BURN, block.timestamp);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
    }

    /**
     * @notice Manually set the PancakeSwap pair address
     * @dev This function is specifically designed for PinkSale FairLaunch integration
     * @dev After PinkSale creates the liquidity pair, this function must be called
     * @dev to ensure the contract recognizes the official trading pair
     * @param _pair Address of the trading pair created by PinkSale
     */
    function setPancakePair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair address");
        require(pancakePair == address(0), "Pair already set");
        pancakePair = _pair;
        isDexPair[_pair] = true;
        emit DexPairUpdated(_pair, true);
    }

    /**
     * @dev Attempts to automatically detect and set up the trading pair
     * @dev This mechanism is a fallback that tries to discover the pair if not set manually
     * @dev For PinkSale launches, manual configuration via setPancakePair() is recommended
     * @dev as it provides stronger guarantees about which pair is the official one
     */
    function _detectAndSetupPair() internal {
        if (pancakePair != address(0)) return;

        address factory = pancakeRouter.factory();
        address pair = IUniswapV2Factory(factory).getPair(
            address(this), 
            pancakeRouter.WETH()
        );
        
        if (pair != address(0)) {
            pancakePair = pair;
            isDexPair[pair] = true;
            emit PairAutoDetected(pair);
            emit DexPairUpdated(pair, true);

            // Auto-approve router for future swaps
            _approve(address(this), address(pancakeRouter), type(uint256).max);
        }
    }

    /**
     * @dev Wrapper function for pair detection that can be called internally
     * @dev This provides a cleaner way to trigger pair detection from other functions
     */
    function autoPairDetection() internal {
        _detectAndSetupPair();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Auto-detection of the pair
        autoPairDetection();

        // Check if burn threshold is reached
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @dev Override of the ERC20 transfer function to implement tax mechanism
     * @dev Handles taxation, burn, marketing allocation and liquidity management
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Amount of tokens being transferred
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Handle self-transfer first
        if (from == to) {
            super._transfer(from, to, amount);
            return;
        }

        // Cache frequently used values
        bool isExcludedFrom = isExcludedFromFees[from];
        bool isExcludedTo = isExcludedFromFees[to];
        bool isDexPairTo = isDexPair[to];
        bool isDexPairFrom = isDexPair[from];

        // Ensure neither sender nor receiver is blacklisted
        require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted");

        // Check max transaction limit
        if (!isExcludedFrom && !isExcludedTo && !isDexPairFrom && !isDexPairTo) {
            require(amount <= MAX_TX_AMOUNT, "Max tx");
        }

        // DEX-to-DEX abuse protection
        if (isDexPairFrom && isDexPairTo && from != address(0) && to != address(0)) {
            require(amount <= maxDexToDexAmount, "DEX transfer too large");
            require(
                lastDexToDexTime[from] == 0 || 
                block.timestamp >= lastDexToDexTime[from] + DEX_TO_DEX_COOLDOWN,
                "DEX transfer cooldown"
            );
            lastDexToDexTime[from] = block.timestamp;
        }

        uint256 taxAmount = 0;

        // Apply tax if applicable
        if (!isExcludedFrom && !isExcludedTo && !taxesRemoved) {
            if (isDexPairFrom && !isDexPairTo) {
                // BUY (DEX → Wallet) - Buy tax 5%
                taxAmount = (amount * buyTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "buy");
            } else if (!isDexPairFrom && isDexPairTo) {
                // SELL (Wallet → DEX) - Sell tax 10%
                taxAmount = (amount * sellTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "sell");
            } else if (!isDexPairFrom && !isDexPairTo) {
                // Transfer between wallets - Sell tax 10%
                taxAmount = (amount * sellTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "transfer");
            }
            // DEX → DEX: No tax (but with protections)
        }

        // Calculate net amount to transfer
        uint256 sendAmount = amount - taxAmount;

        // Perform the net transfer (SINGLE TRANSFER ONLY!)
        super._transfer(from, to, sendAmount);

        // Handle taxes if any
        if (taxAmount > 0) {
            uint256 burnAmount = (taxAmount * BURN_PERCENT) / 100;
            uint256 marketingAmount = (taxAmount * MARKETING_PERCENT) / 100;
            uint256 liquidityAmount = taxAmount - burnAmount - marketingAmount;

            // Burn tokens directly from the sender
            if (burnAmount > 0) {
                _burn(from, burnAmount);
                burnedTokens += burnAmount;
            }

            // Transfer marketing amount to contract
            if (marketingAmount > 0) {
                super._transfer(from, address(this), marketingAmount);
            }

            // Handle liquidity
            if (liquidityAmount > 0) {
                super._transfer(from, address(this), liquidityAmount);

                if (swapEnabled && !inSwapAndLiquify && !isDexPair[from] && !isDexPair[to]) {
                    swapAndLiquify(liquidityAmount);
                }
            }
        }
    }

    /**
 * @notice Swaps tokens for BNB using PancakeSwap with slippage protection
 * @dev Includes 5% slippage protection to prevent frontrunning attacks
 * @dev This is a private function called during automatic liquidity operations
 * @param tokenAmount Amount of tokens to swap for BNB
 */
function swapTokensForBNB(uint256 tokenAmount) private {
    // Generate the Uniswap pair path of token -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    // Make sure the contract has allowed the router to spend these tokens
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // Protection against frontrunning
    uint256 minAmountOut = 0;
    if (pancakePair != address(0)) {
        try pancakeRouter.getAmountsOut(tokenAmount, path) returns (uint256[] memory amounts) {
            minAmountOut = amounts[1] * 95 / 100; // 5% slippage maximum
        } catch {
            // Fallback in case estimation fails
            minAmountOut = 0;
        }
    }

    uint256 initialBalance = address(this).balance;
    try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        minAmountOut, // Use the calculated minimum amount
        path,
        address(this),
        block.timestamp
    ) {
        // Swap succeeded
    } catch {
        revert("Token to BNB swap failed");
    }

    // Verify the amount of ETH received after the swap
    uint256 ethReceived = address(this).balance - initialBalance;
    require(ethReceived > 0, "No ETH received from swap");
}

/**
 * @notice Adds liquidity to the PancakeSwap pool
 * @dev Private function that pairs tokens with BNB for liquidity provision
 * @param tokenAmount Amount of tokens to add to liquidity pool
 * @param bnbAmount Amount of BNB to add to liquidity pool
 */
function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // Add the liquidity
    pancakeRouter.addLiquidityETH{value: bnbAmount}(
        address(this),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        owner(),
        block.timestamp
    );
}

    /**
 * @notice Automatically swaps accumulated tokens for BNB and adds to liquidity
 * @dev This function is called automatically during transactions when conditions are met
 * @dev Protected by lockTheSwap modifier to prevent reentrancy
 * @param contractTokenBalance Amount of tokens accumulated in the contract to swap
 */
function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    require(contractTokenBalance > 0, "No tokens to swap");

    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    uint256 initialBalance = address(this).balance;
    swapTokensForBNB(half);
    uint256 newBalance = address(this).balance - initialBalance;

    addLiquidity(otherHalf, newBalance);
    
    emit SwapAndLiquifyCompleted(half, newBalance, otherHalf);
}


    /**
 * @notice Manually triggers the swap of accumulated tokens to BNB and adds to liquidity
 * @param contractTokenBalance Amount of tokens to swap
 * @dev This function is called manually by the owner to convert accumulated taxes
 */
    function triggerSwapAndLiquify(uint256 contractTokenBalance) external onlyOwner {
        swapAndLiquify(contractTokenBalance);
    }

    /**
     * @notice Internal function to permanently remove all taxes when burn threshold is reached
     * @dev Automatically called when burnedTokens >= BURN_THRESHOLD
     * @dev Sets both buyTax and sellTax to 0% permanently - this action cannot be reversed
     * @dev Emits TaxesRemoved event to notify of this significant tokenomics change
     * @dev This creates a deflationary token that becomes fee-free once enough is burned
     */
    function _removeTaxes() internal {
        require(!taxesRemoved, "Taxes already removed");
        buyTax = 0;
        sellTax = 0;
        taxesRemoved = true;
        emit TaxesRemoved();
    }

    function removeTaxes() external onlyOwner {
        _removeTaxes();
    }

    function renounceContract() external onlyOwner {
        renounceOwnership();
    }

    function blacklistAddress(address _address, bool _status) external onlyOwner {
        isBlacklisted[_address] = _status;
    }

    /**
     * @notice Blacklist multiple addresses at once
     * @param addresses Array of addresses to blacklist
     * @param status True to blacklist, false to remove from blacklist
     */
    function blacklistAddresses(address[] memory addresses, bool status) external onlyOwner {
        require(addresses.length > 0, "Empty array");
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Zero address");
            isBlacklisted[addresses[i]] = status;
        }
    }

    /**
     * @notice Check if an address is blacklisted
     * @param _address Address to check
     * @return bool True if address is blacklisted
     */
    function getBlacklistStatus(address _address) public view returns (bool) {
        return isBlacklisted[_address];
    }

    function excludeFromFees(address _address, bool _status) public onlyOwner {
        isExcludedFromFees[_address] = _status;
    }

    /**
     * @notice Exclude multiple accounts from fees
     * @param accounts Array of addresses to exclude
     * @param excluded True to exclude, false to include
     */
    function excludeMultipleAccountsFromFees(
        address[] memory accounts,
        bool excluded
    ) external onlyOwner {
        require(accounts.length > 0, "Empty array");
        for(uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Zero address");
            isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function setDexPair(address _pair, bool _status) external onlyOwner {
        isDexPair[_pair] = _status;
        emit DexPairUpdated(_pair, _status);
    }

    function getBuyTax() public view returns (uint256) {
        return buyTax;
    }

    function getSellTax() public view returns (uint256) {
        return sellTax;
    }

    /**
     * @notice Manually burns tokens from a specific account
     * @dev Can only be called by owner, increments burnedTokens counter
     * @dev Will trigger automatic tax removal if burn threshold is reached
     * @param account Address from which to burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(address account, uint256 amount) public onlyOwner {
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _burn(account, amount);
        burnedTokens += amount;
        
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @notice Returns the total amount of tokens that have been burned
     * @return uint256 Total burned token amount
     */
    function getBurnedTokens() public view returns (uint256) {
        return burnedTokens;
    }

    /**
     * @notice Checks if an address is excluded from paying fees
     * @param _address The address to check
     * @return bool True if the address is excluded from fees
     */
    function isAddressExcludedFromFees(address _address) public view returns (bool) {
        return isExcludedFromFees[_address];
    }

    /**
     * @notice Returns the maximum amount allowed in a single transaction
     * @return uint256 Maximum transaction amount
     */
    function getMaxTransactionAmount() public pure returns (uint256) {
        return MAX_TX_AMOUNT;
    }

    /**
     * @notice External wrapper for excludeFromFees function
     * @dev Allows excluding addresses from fees through external calls
     * @param _address Address to exclude or include
     * @param _status True to exclude, false to include
     */
    function excludeFromFeesExternal(address _address, bool _status) external onlyOwner {
        excludeFromFees(_address, _status);
    }

    /**
     * @notice Prepares distribution of funds by calculating amounts for each wallet
     * @dev Creates a distribution queue that must be processed with distributeFunds()
     * @dev Enforces a block delay between distributions for security
     */
    function queueDistribution() public onlyOwner {
        require(address(this).balance > 0, "No funds to distribute");
        require(!distributionQueued, "Distribution already queued");
        require(block.number > lastDistributionBlock + DISTRIBUTION_DELAY, "Distribution delay not met");
        
        uint256 totalBalance = address(this).balance;
        
        pendingDistributions[marketingWallet] = (totalBalance * marketingShare) / 100;
        pendingDistributions[cexWallet] = (totalBalance * cexShare) / 100;
        pendingDistributions[operationsWallet] = (totalBalance * operationsShare) / 100;
        
        distributionQueued = true;
        lastDistributionBlock = block.number;
    }
    
    /**
     * @notice Processes the distribution of funds to a specific wallet
     * @dev Follows Check-Effects-Interactions pattern to prevent reentrancy issues
     * @param wallet Address of the wallet to receive funds
     */
    function processDistribution(address wallet) public nonReentrant onlyOwner {
        uint256 amount = pendingDistributions[wallet];
        require(amount > 0, "No funds queued for this wallet");
        
        // Update state before external interaction
        pendingDistributions[wallet] = 0;
        
        if (wallet == operationsWallet && 
            pendingDistributions[marketingWallet] == 0 && 
            pendingDistributions[cexWallet] == 0) {
            distributionQueued = false;
        }
        
        // External interaction last
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @notice Distributes accumulated BNB to configured wallets
     * @dev Distributes BNB according to percentages defined in marketingShare, cexShare and operationsShare
     */
    function distributeFunds() external onlyOwner {
        require(address(this).balance > 0, "No funds to distribute");
        
        queueDistribution();
        
        // Store values before zeroing them out
        uint256 marketingAmount = pendingDistributions[marketingWallet];
        uint256 cexAmount = pendingDistributions[cexWallet];
        uint256 operationsAmount = pendingDistributions[operationsWallet];
        
        processDistribution(marketingWallet);
        processDistribution(cexWallet);
        processDistribution(operationsWallet);
        
        // Emit event with correct amounts
        emit FundsDistributed(marketingAmount, cexAmount, operationsAmount);
    }
    
    /**
     * @notice Updates the wallet addresses for fund distribution
     * @dev Should be called after deployment to set up dedicated wallets
     * @param _marketingWallet Address of the marketing wallet
     * @param _cexWallet Address of the CEX wallet
     * @param _operationsWallet Address of the operations wallet
     */
    function updateWallets(
        address _marketingWallet,
        address _cexWallet,
        address _operationsWallet
    ) external onlyOwner {
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_cexWallet != address(0), "Invalid CEX wallet");
        require(_operationsWallet != address(0), "Invalid operations wallet");
        
        marketingWallet = _marketingWallet;
        cexWallet = _cexWallet;
        operationsWallet = _operationsWallet;
        
        emit WalletsUpdated(_marketingWallet, _cexWallet, _operationsWallet);
    }
    
    /**
     * @notice Updates the distribution shares for each wallet
     * @param _marketingShare Percentage for marketing wallet (out of 100)
     * @param _cexShare Percentage for CEX wallet (out of 100)
     * @param _operationsShare Percentage for operations wallet (out of 100)
     */
    function updateShares(
        uint256 _marketingShare,
        uint256 _cexShare,
        uint256 _operationsShare
    ) external onlyOwner {
        require(_marketingShare + _cexShare + _operationsShare == 100, "Shares must add up to 100");
        marketingShare = _marketingShare;
        cexShare = _cexShare;
        operationsShare = _operationsShare;
        emit SharesUpdated(_marketingShare, _cexShare, _operationsShare);
    }

    /**
     * @notice Returns key token constants for testing and UI
     * @return totalSupply The total token supply
     * @return initialBurn The initial burn amount
     * @return burnThreshold The burn threshold amount
     * @return maxTxAmount The maximum transaction amount
     */
    function getTokenConstants() external pure returns (
        uint256 totalSupply,
        uint256 initialBurn,
        uint256 burnThreshold,
        uint256 maxTxAmount
    ) {
        totalSupply = TOTAL_SUPPLY;
        initialBurn = INITIAL_BURN;
        burnThreshold = BURN_THRESHOLD;
        maxTxAmount = MAX_TX_AMOUNT;
    }

    /**
     * @notice Returns the current tax distribution percentages
     * @return burnShare Percentage of tax allocated to burn
     * @return marketingShare_ Percentage of tax allocated to marketing
     * @return liquidityShare_ Percentage of tax allocated to liquidity
     */
    function getTaxDistribution() external pure returns (
        uint256 burnShare,
        uint256 marketingShare_,
        uint256 liquidityShare_
    ) {
        burnShare = 60;
        marketingShare_ = 25;
        liquidityShare_ = 15;
    }

    /**
     * @notice Enable or disable automatic swap and liquify
     * @param enabled Whether automatic swaps should be enabled
     */
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        emit SwapEnabledUpdated(enabled);
    }

    /**
     * @notice Configure limits for DEX → DEX transfers
     * @param _maxAmount Maximum amount allowed (0 = no limit)
     */
    function setDexToDexLimit(uint256 _maxAmount) external onlyOwner {
        maxDexToDexAmount = _maxAmount;
    }

    /**
     * @notice Check DEX → DEX status for an address
     * @param account Address to check
     * @return canTransfer Whether can transfer now
     * @return timeLeft Time remaining before next transfer (in seconds)
     */
    function getDexToDexStatus(address account) external view returns (
        bool canTransfer,
        uint256 timeLeft
    ) {
        // FIXED: If no previous transfer, allow
        if (lastDexToDexTime[account] == 0) {
            canTransfer = true;
            timeLeft = 0;
            return (canTransfer, timeLeft);
        }
        
        uint256 nextAllowedTime = lastDexToDexTime[account] + DEX_TO_DEX_COOLDOWN;
        canTransfer = block.timestamp >= nextAllowedTime;
        timeLeft = canTransfer ? 0 : nextAllowedTime - block.timestamp;
    }

    /**
     * @notice Fallback function to receive BNB
     * @dev Required for receiving BNB from router swaps
     */
    receive() external payable {}
}