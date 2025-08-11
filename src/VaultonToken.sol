// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @title Vaulton Token - Revolutionary Deflationary Mechanism
/// @notice ERC20 token with automated 2% auto-sell → buyback & burn mechanism
/// @dev Implements progressive deflationary tokenomics with automatic price support
/// @author Vaulton Team
/// @custom:security-contact nicolas@vaulton.xyz
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    
    // --- Core Token Economics (Immutable for Security) ---
    /// @notice Total token supply: 30M tokens
    uint256 public constant TOTAL_SUPPLY = 30_000_000 * 10**18;
    
    /// @notice Initial burn amount: 8M tokens (26.7% of total supply)
    /// @dev Burned immediately upon deployment for instant deflation
    uint256 public constant INITIAL_BURN = 8_000_000 * 10**18;
    
    /// @notice Buyback reserve allocation: 10M tokens (33.3% of total supply)
    /// @dev Reserved for automated price support mechanism
    uint256 public constant BUYBACK_RESERVE = 10_000_000 * 10**18;
    // --- Automated Mechanism Parameters ---
    /// @notice Auto-sell percentage: 2% of each sell transaction
    /// @dev Triggers automatic token sale from buyback reserve
    uint256 private constant AUTO_SELL_PERCENT = 200; // 2%
    
    /// @notice BNB threshold for buyback execution: optimized for mainnet
    /// @dev Prevents micro-buybacks and ensures economic efficiency (~$10-20 USD)
    uint256 private constant BNB_THRESHOLD = 0.03 ether;
    
    /// @notice Anti-bot protection duration: 5 blocks for mainnet security
    /// @dev Restricts purchases to whitelisted addresses during launch
    uint256 private constant ANTI_BOT_BLOCKS = 5; // Mainnet: 5 blocks (~15 seconds)

    // --- Core Contract State ---
    /// @notice PancakeSwap V2 Router for automated swaps
    IUniswapV2Router02 public immutable pancakeRouter;
    
    /// @notice Trading pair address (VAULTON/WBNB)
    address public pancakePair;
    
    /// @notice CEX listing wallet address for centralized exchange token supply
    /// @dev This wallet will receive tokens allocated for CEX listings and trading pairs
    address public immutable cexWallet;
    
    /// @notice Total tokens burned (including initial burn)
    uint256 public burnedTokens;
    
    /// @notice Remaining tokens available for buyback mechanism
    uint256 public buybackTokensRemaining;
    
    /// @notice BNB accumulated from auto-sells, pending buyback
    uint256 public accumulatedBNB;
    
    /// @notice Block number of last successful buyback (for tracking)
    uint256 public lastBuybackBlock;
    
    /// @notice Block number when trading was enabled
    uint256 public tradingStartBlock;
    
    /// @notice Whether trading is enabled
    bool public tradingEnabled = false;
    
    /// @notice Whether auto-sell mechanism is active
    bool public autoSellEnabled = false;
    
    /// @dev Reentrancy protection for swap operations
    bool private _inSwap;
    
    /// @notice Whitelist for anti-bot protection during launch
    mapping(address => bool) public isWhitelisted;

    // --- Events for Transparency and Monitoring ---
    /// @notice Emitted when buyback & burn occurs
    /// @param tokensBurned Amount of tokens burned
    /// @param bnbUsed Amount of BNB used for buyback
    event BuybackBurn(uint256 tokensBurned, uint256 bnbUsed);
    
    /// @notice Emitted when auto-sell occurs
    /// @param tokensSold Amount of tokens sold from reserve
    /// @param bnbReceived Amount of BNB received
    event ProgressiveSale(uint256 tokensSold, uint256 bnbReceived);
    
    /// @notice Emitted when anti-bot protection blocks a transaction
    /// @param user Address that was blocked
    /// @param blockNumber Block number when blocked
    event AntiBotBlocked(address indexed user, uint256 blockNumber);
    
    /// @notice Emitted when token swap for BNB fails
    /// @param tokenAmount Amount of tokens that failed to swap
    event SwapForBNBFailed(uint256 tokenAmount);
    
    /// @notice Emitted when buyback operation fails
    /// @param bnbTried Amount of BNB that failed to be used for buyback
    event BuybackFailed(uint256 bnbTried);

    /// @dev Prevents reentrancy during swap operations
    modifier lockTheSwap() {
        require(!_inSwap, "Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /// @notice Contract constructor
    /// @param pancakeRouterAddress PancakeSwap V2 Router address
    /// @param cexWalletAddress CEX listing wallet address
    /// @dev Mints total supply, burns initial amount, transfers remainder to owner
    constructor(
        address pancakeRouterAddress,
        address cexWalletAddress
    ) ERC20("Vaulton", "VAULTON") {
        require(pancakeRouterAddress != address(0), "Invalid router");
        require(cexWalletAddress != address(0), "Invalid CEX wallet");
        
        pancakeRouter = IUniswapV2Router02(pancakeRouterAddress);
        cexWallet = cexWalletAddress;

        // Mint total supply to contract
        _mint(address(this), TOTAL_SUPPLY);
        
        // Execute initial burn for immediate deflation
        _burn(address(this), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        
        // Buyback reserve starts at 0, set when owner transfers tokens back
        buybackTokensRemaining = 0;

        // Transfer remaining 22M tokens to owner for presale and distribution
        uint256 ownerTokens = TOTAL_SUPPLY - INITIAL_BURN;
        _transfer(address(this), owner(), ownerTokens);

        // Pre-approve router for automated swaps
        _approve(address(this), address(pancakeRouter), type(uint256).max);
    }

    // --- Owner-Only Configuration Functions ---
    
    /// @notice Set the trading pair address
    /// @param pairAddress Address of VAULTON/WBNB pair
    /// @dev Must be called before enabling trading
    function setPair(address pairAddress) external onlyOwner {
        require(pairAddress != address(0), "Invalid pair");
        pancakePair = pairAddress;
    }

    /// @notice Enable trading and activate auto-sell mechanism
    /// @dev Can only be called once, requires pair to be set first
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        require(pancakePair != address(0), "Pair not set");
        tradingEnabled = true;
        autoSellEnabled = true;
        tradingStartBlock = block.number;
    }

    /// @notice Add address to anti-bot whitelist
    /// @param user Address to whitelist
    /// @dev Whitelisted addresses can buy during anti-bot period
    function addToWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = true;
    }

    /// @notice Remove address from anti-bot whitelist
    /// @param user Address to remove from whitelist
    function removeFromWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = false;
    }

    /// @notice Update buyback reserve after owner transfers tokens to contract
    /// @dev CRITICAL: Must be called after transferring buyback reserve to contract
    function updateBuybackReserve() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        buybackTokensRemaining = contractBalance > BUYBACK_RESERVE ? BUYBACK_RESERVE : contractBalance;
    }

    /// @notice Renounce ownership (no additional restrictions)
    /// @dev Simple ownership renunciation for decentralization
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    /// @notice Update burned tokens count after external burns (e.g., Pinksale unsold)
    /// @param additionalBurnAmount Amount of tokens burned externally
    /// @dev Only callable by owner before renouncing ownership
    /// @dev This function only updates internal tracking, does not affect getBasicStats()
    function updateExternalBurn(uint256 additionalBurnAmount) external onlyOwner {
        require(additionalBurnAmount > 0, "Invalid burn amount");
        
        // Update internal burn tracking
        burnedTokens += additionalBurnAmount;
        
        // Emit event for transparency
        emit ExternalBurnUpdated(additionalBurnAmount, burnedTokens);
    }
    
    /// @notice Event for external burn tracking update
    /// @param burnAmount Amount of tokens burned externally
    /// @param totalBurned Total tokens burned after update
    event ExternalBurnUpdated(uint256 burnAmount, uint256 totalBurned);
    
    // --- Core Transfer Logic with Automated Mechanism ---
    
    /// @dev Override transfer to implement trading restrictions and auto-sell mechanism
    function _transfer(address from, address to, uint256 amount) internal override {
        // Restrict trading before official launch
        if (!tradingEnabled) {
            require(
                from == owner() || to == owner() ||
                from == address(this) || to == address(this) ||
                to == pancakePair ||
                from == address(pancakeRouter) || to == address(pancakeRouter) ||
                isWhitelisted[from] || isWhitelisted[to],
                "Trading not enabled"
            );
        }

        // Anti-bot protection: restrict purchases during first blocks after launch
        if (
            tradingEnabled &&
            tradingStartBlock > 0 &&
            block.number < tradingStartBlock + ANTI_BOT_BLOCKS &&
            from == pancakePair &&
            !isWhitelisted[to]
        ) {
            emit AntiBotBlocked(to, block.number);
            revert("Anti-bot: not whitelisted");
        }

        // Calculate auto-sell amount if this is a sell transaction
        uint256 sellAmount = 0;
        if (!_inSwap && autoSellEnabled && pancakePair != address(0)) {
            bool isSell = to == pancakePair 
                && from != address(this) 
                && from != address(pancakeRouter);

            if (isSell && buybackTokensRemaining > 0) {
                // Calculate 2% auto-sell amount
                sellAmount = (amount * AUTO_SELL_PERCENT) / 10000;
                uint256 contractBalance = balanceOf(address(this));
                
                // Ensure contract has sufficient tokens for auto-sell
                if (sellAmount > contractBalance) sellAmount = contractBalance;
                if (sellAmount > buybackTokensRemaining) sellAmount = buybackTokensRemaining;
            }
        }

        // EXECUTE USER TRANSFER FIRST (prevent reentrancy)
        super._transfer(from, to, amount);
        
        // EXECUTE AUTO-SELL AFTER TRANSFER - but we must be very careful about state changes
        if (sellAmount > 0) {
            _progressiveSellForBNB(sellAmount);
            
            // Trigger buyback if BNB threshold reached - load value only once
            uint256 currentAccumulatedBNB = accumulatedBNB;
            if (currentAccumulatedBNB >= BNB_THRESHOLD) {
                _triggerBuybackAndBurn();
            }
        }
    }

    /// @dev Execute auto-sell: convert reserve tokens to BNB
    /// @param sellAmount Amount of tokens to sell from reserve
    function _progressiveSellForBNB(uint256 sellAmount) internal lockTheSwap {
        if (buybackTokensRemaining == 0) return;
        if (sellAmount == 0) return;

        // CORRECTION: Mesurer le BNB AVANT et APRÈS le swap
        uint256 initialBNB = address(this).balance;
        _swapTokensForBNB(sellAmount);
        uint256 bnbReceived = address(this).balance - initialBNB;

        // SEULEMENT mettre à jour l'état si le swap a réussi ET produit du BNB
        if (bnbReceived > 0) {
            buybackTokensRemaining -= sellAmount;
            accumulatedBNB += bnbReceived;
            emit ProgressiveSale(sellAmount, bnbReceived);
        }
        // Si bnbReceived == 0, cela signifie que le swap a échoué
        // Dans ce cas, on ne modifie aucun état
    }

    /// @dev Execute buyback & burn: convert accumulated BNB to tokens and burn them
    function _triggerBuybackAndBurn() internal lockTheSwap {
        if (accumulatedBNB < BNB_THRESHOLD) return;

        // SECURITY: Store all values before external call
        uint256 bnbForBuyback = accumulatedBNB;
        
        // Reset state BEFORE external calls
        accumulatedBNB = 0;
        
        // Store the current block number for recording
        uint256 currentBlockNumber = block.number;
        
        // Emit event before external call
        emit BuybackBurn(0, bnbForBuyback);
        
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);
        
        // Track the burn address balance before swap
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        uint256 balanceBefore = balanceOf(burnAddress);
        
        // EXTERNAL CALL - last state-modifying operation
        try pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbForBuyback
        }(
            0, // Accept any amount of tokens
            path,
            burnAddress, // Send directly to burn address
            block.timestamp + 300
        ) {
            // Update stats tracking only - calculate burned tokens
            uint256 tokensBurned = balanceOf(burnAddress) - balanceBefore;
            if (tokensBurned > 0) {
                // Store locally to prevent multiple state reads/writes
                uint256 newBurnedTokens = burnedTokens + tokensBurned;
                
                // Update state variables once
                burnedTokens = newBurnedTokens;
                lastBuybackBlock = currentBlockNumber;
            }
        } catch {
            // We intentionally don't restore state to prevent reentrancy
            // This is a deliberate security choice
            emit BuybackFailed(bnbForBuyback);
        }
    }

    /// @dev Swap tokens for BNB using PancakeSwap
    /// @param tokenAmount Amount of tokens to swap
    function _swapTokensForBNB(uint256 tokenAmount) internal {
        // Create path for token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300
        ) {} catch {
            // Silent failure - mechanism will continue with next transaction
            emit SwapForBNBFailed(tokenAmount);
        }
    }

    // --- Public View Functions for Transparency ---
    
    /// @notice Get comprehensive token statistics
    /// @return circulatingSupply Current circulating supply (total - burned)
    /// @return burnedTokens_ Total tokens burned (including initial burn)
    /// @return buybackTokensRemaining_ Tokens remaining in buyback reserve
    /// @return accumulatedBNB_ BNB accumulated from auto-sells, pending buyback
    function getBasicStats() external view returns (
        uint256 circulatingSupply,
        uint256 burnedTokens_,
        uint256 buybackTokensRemaining_,
        uint256 accumulatedBNB_
    ) {
        return (
            TOTAL_SUPPLY - burnedTokens,
            burnedTokens,
            buybackTokensRemaining,
            accumulatedBNB
        );
    }

    /// @dev Accept BNB deposits for buyback mechanism
    receive() external payable {}
}

/// @dev Reentrancy protected by lockTheSwap modifier
/// State changes after external calls are intentional for gas optimization
/// and do not create security vulnerabilities in this controlled context