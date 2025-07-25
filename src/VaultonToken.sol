// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @title Vaulton Token
/// @author YourName
/// @notice ERC20 token with buyback & burn, anti-bot, and auto-sell features.
/// @dev Designed for transparency and security, ready for audit.
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // --- Supply & burn ---

    /// @notice Total supply of the token (30 million)
    uint256 public constant TOTAL_SUPPLY = 30_000_000 * 10**18;
    /// @notice Initial burn amount (8 million)
    uint256 public constant INITIAL_BURN = 8_000_000 * 10**18;
    /// @notice Reserve for buyback & burn (11 million)
    uint256 public constant BUYBACK_RESERVE = 11_000_000 * 10**18;
    /// @notice Total tokens burned (all mechanisms)
    uint256 public burnedTokens;
    /// @notice Remaining tokens available for buyback & burn
    uint256 public buybackTokensRemaining;
    /// @notice Total tokens sold for BNB accumulation (auto-sell)
    uint256 public totalBuybackTokensSold;
    /// @notice Total tokens burned via buyback & burn
    uint256 public totalBuybackTokensBurned;
    /// @notice Block number of the last buyback
    uint256 public lastBuybackBlock;

    // --- Buyback & sell parameters ---

    /// @notice BNB threshold to trigger a buyback
    uint256 public BNB_THRESHOLD = 0.005 ether;
    /// @notice Minimum BNB threshold allowed
    uint256 public constant MIN_BNB_THRESHOLD = 1;
    /// @notice Percentage of reserve to auto-sell (base 10000)
    uint256 public AUTO_SELL_PERCENT = 500;
    /// @notice Minimum tokens to auto-sell
    uint256 public constant MIN_AUTO_SELL = 10 * 10**18;
    /// @notice Maximum tokens to auto-sell
    uint256 public constant MAX_AUTO_SELL = 1000 * 10**18;
    /// @notice BNB accumulated for next buyback
    uint256 public accumulatedBNB;
    /// @notice Number of auto-sell operations performed
    uint256 public totalSellOperations;

    // --- DEX addresses ---
    IUniswapV2Router02 public immutable pancakeRouter;
    address public pancakePair;
    address public marketingWallet;

    // --- Trading & swap state ---
    bool public tradingEnabled;
    bool public autoSellEnabled = true;
    bool private _inSwap;

    /// @notice Prevents reentrancy during swaps
    modifier lockTheSwap() {
        require(!_inSwap, "Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    // --- Owner configuration ---

    /// @notice Set the BNB threshold for triggering buybacks
    /// @param newThreshold New BNB threshold (must be >= MIN_BNB_THRESHOLD)
    function setBNBThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold >= MIN_BNB_THRESHOLD, "Threshold too low");
        BNB_THRESHOLD = newThreshold;
    }

    /// @notice Set the auto-sell percentage (base 10000)
    /// @param newPercent New auto-sell percent (max 2%)
    function setAutoSellPercent(uint256 newPercent) external onlyOwner {
        require(newPercent <= 200, "Max 2% recommended");
        AUTO_SELL_PERCENT = newPercent;
    }

    /// @notice Enable or disable auto-sell
    /// @param enabled True to enable, false to disable
    function setAutoSellEnabled(bool enabled) external onlyOwner {
        autoSellEnabled = enabled;
    }

    /// @notice Manually burn tokens from the buyback reserve
    /// @param amount Amount of tokens to burn
    function manualReserveBurn(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(amount <= buybackTokensRemaining, "Exceeds reserve");
        uint256 contractBalance = balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient contract balance");
        _burn(address(this), amount);
        burnedTokens += amount;
        buybackTokensRemaining -= amount;
        totalBuybackTokensBurned += amount;
        emit ManualReserveBurn(msg.sender, amount, burnedTokens);
        emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
    }

    // --- Anti-bot system ---
    uint256 public tradingStartBlock;
    uint256 public constant ANTI_BOT_BLOCKS = 5;
    mapping(address => bool) public isWhitelisted;

    /// @notice Emitted when a non-whitelisted address is blocked during anti-bot phase
    event AntiBotBlocked(address indexed user, uint256 blockNumber);

    /// @notice Add an address to the anti-bot whitelist
    function addToWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = true;
    }
    /// @notice Remove an address from the anti-bot whitelist
    function removeFromWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = false;
    }

    // --- Token recovery (non-native) ---
    /// @notice Recover ERC20 tokens sent to this contract by mistake (not VAULTON)
    event RecoveredERC20(address token, uint256 amount);
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "Cannot recover VAULTON");
        IERC20(token).transfer(owner(), amount);
        emit RecoveredERC20(token, amount);
    }

    /// @notice Emitted on swap errors
    event SwapError(string reason);

    // --- Constructor: mint, burn, distribute, approve router ---
    /// @notice Deploys the Vaulton token, burns initial supply, sets up buyback reserve and router approvals
    /// @param _pancakeRouter PancakeSwap router address
    /// @param _marketingWallet Marketing wallet address
    constructor(address _pancakeRouter, address _marketingWallet) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        marketingWallet = _marketingWallet;

        _mint(address(this), TOTAL_SUPPLY);
        _burn(address(this), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        buybackTokensRemaining = BUYBACK_RESERVE;

        uint256 ownerTokens = TOTAL_SUPPLY - INITIAL_BURN - BUYBACK_RESERVE - 1_000_000 * 10**18;
        _transfer(address(this), owner(), ownerTokens);
        _transfer(address(this), marketingWallet, 1_000_000 * 10**18);

        _approve(address(this), address(_pancakeRouter), type(uint256).max);
    }

    // --- PinkSale compatibility ---
    /// @notice Approve a router for spending tokens (for DEX listing)
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router");
        _approve(address(this), _router, type(uint256).max);
    }

    /// @notice Set the DEX pair address
    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair");
        pancakePair = _pair;
    }

    /// @notice Enable trading and record the start block
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        require(pancakePair != address(0), "Pair not set");
        tradingEnabled = true;
        tradingStartBlock = block.number;
    }

    // --- Ownership overrides ---
    function owner() public view override returns (address) {
        return super.owner();
    }

    /// @notice Renounce ownership and disable auto-sell
    function renounceOwnership() public override onlyOwner {
        autoSellEnabled = false;
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // --- Core transfer logic with auto-sell and anti-bot ---
    /// @dev Handles anti-bot, auto-sell, and triggers buyback if threshold is met
    function _transfer(address from, address to, uint256 amount) internal override {
        // Restrict trading before launch
        if (!tradingEnabled) {
            require(
                from == owner() || to == owner() ||
                from == address(this) || to == address(this) ||
                to == pancakePair ||
                from == address(pancakeRouter) || to == address(pancakeRouter),
                "Trading not enabled"
            );
        }

        // Anti-bot: restrict buys in first blocks to whitelisted addresses
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

        // Auto-sell logic on sell to DEX
        if (!_inSwap && autoSellEnabled && pancakePair != address(0)) {
            bool isSell = to == pancakePair 
                && from != address(this) 
                && from != address(pancakeRouter);

            if (isSell) {
                uint256 sellAmount = (amount * AUTO_SELL_PERCENT) / 10000;
                if (sellAmount > MAX_AUTO_SELL) sellAmount = MAX_AUTO_SELL;
                if (sellAmount > buybackTokensRemaining) sellAmount = buybackTokensRemaining;
                uint256 contractBalance = balanceOf(address(this));
                if (sellAmount > contractBalance) sellAmount = contractBalance;
                if (sellAmount > 0) {
                    _progressiveSellForBNB(sellAmount);
                }
                if (accumulatedBNB >= BNB_THRESHOLD) {
                    _triggerBuybackAndBurn();
                }
            }
        }

        super._transfer(from, to, amount);
    }

    // --- Swap tokens for BNB and accumulate for buyback ---
    /// @dev Sells tokens for BNB and accumulates for buyback
    /// @param sellAmount Amount of tokens to sell
    function _progressiveSellForBNB(uint256 sellAmount) internal lockTheSwap {
        if (buybackTokensRemaining == 0) return;
        if (sellAmount == 0) return;
        if (balanceOf(address(this)) < sellAmount) return;

        uint256 initialBNB = address(this).balance;
        _swapTokensForBNB(sellAmount);
        uint256 bnbReceived = address(this).balance - initialBNB;

        if (bnbReceived > 0) {
            buybackTokensRemaining -= sellAmount;
            totalBuybackTokensSold += sellAmount;
            totalSellOperations++;
            lastBuybackBlock = block.number;
            accumulatedBNB += bnbReceived;
            emit ProgressiveSale(sellAmount, bnbReceived, accumulatedBNB);
        }
    }

    // --- Slippage protection ---
    uint256 public slippagePercent = 50;
    uint256 public constant MAX_SLIPPAGE = 500;

    /// @notice Set slippage percent for swaps (base 10000)
    /// @param newPercent New slippage percent (max 5%)
    function setSlippagePercent(uint256 newPercent) external onlyOwner {
        require(newPercent <= MAX_SLIPPAGE, "Slippage too high");
        slippagePercent = newPercent;
    }

    // --- Gas limit for swaps ---
    uint256 public swapGasLimit = 500_000;
    /// @notice Set gas limit for swap operations
    /// @param newLimit New gas limit (between 100,000 and 2,000,000)
    function setSwapGasLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 100_000 && newLimit <= 2_000_000, "Gas limit out of range");
        swapGasLimit = newLimit;
    }

    // --- Internal swap logic ---
    /// @dev Swaps tokens for BNB using PancakeRouter
    /// @param tokenAmount Amount of tokens to swap
    function _swapTokensForBNB(uint256 tokenAmount) internal {
        require(address(pancakeRouter) != address(0), "Router not set");
        require(pancakePair != address(0), "Pair not set");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        uint256 minOut;
        bool slippageOk = true;
        try pancakeRouter.getAmountsOut(tokenAmount, path) returns (uint256[] memory amountsOut) {
            minOut = amountsOut[1] - ((amountsOut[1] * slippagePercent) / 10000);
        } catch {
            slippageOk = false;
            emit SwapError("Slippage calculation failed");
        }

        if (!slippageOk) return;

        try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens{
            gas: swapGasLimit
        }(
            tokenAmount,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        ) {
        } catch Error(string memory reason) {
            emit SwapError(reason);
        } catch {
            emit SwapError("Unknown error");
        }
    }

    // --- Buyback & burn logic ---
    /// @dev Executes buyback & burn using accumulated BNB
    function _triggerBuybackAndBurn() internal lockTheSwap {
        if (accumulatedBNB < MIN_BNB_THRESHOLD) return;

        uint256 bnbForBuyback = accumulatedBNB;
        accumulatedBNB = 0;

        totalBuybacks += 1;
        totalBuybackBNB += bnbForBuyback;

        emit BuybackTriggered(msg.sender, bnbForBuyback, block.timestamp);

        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        uint256 minTokensOut = 0;
        try pancakeRouter.getAmountsOut(bnbForBuyback, path) returns (uint256[] memory amountsOut) {
            minTokensOut = amountsOut[1] - ((amountsOut[1] * slippagePercent) / 10000);
        } catch {
            minTokensOut = 0;
        }

        address burnAddress = 0x000000000000000000000000000000000000dEaD;

        try pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbForBuyback,
            gas: swapGasLimit
        }(
            minTokensOut,
            path,
            burnAddress,
            block.timestamp + 300
        ) {
            burnedTokens += minTokensOut;
            totalBuybackTokensBurned += minTokensOut;
            emit BuybackBurn(minTokensOut, bnbForBuyback, burnedTokens);
            emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
        } catch Error(string memory reason) {
            emit SwapError(reason);
            accumulatedBNB = bnbForBuyback;
        } catch {
            emit SwapError("Unknown error");
            accumulatedBNB = bnbForBuyback;
        }
    }

    // --- Global statistics for analytics/front-end ---
    /// @notice Returns global stats for analytics and front-end
    /// @return totalSupply_ Total supply
    /// @return circulatingSupply Circulating supply
    /// @return burnedTokens_ Total burned tokens
    /// @return buybackTokensRemaining_ Buyback reserve remaining
    /// @return totalBuybackTokensSold_ Tokens sold for BNB (auto-sell)
    /// @return totalBuybackTokensBurned_ Tokens burned via buyback
    /// @return totalBuybacks_ Number of buybacks
    /// @return avgBlocksPerBuyback Average blocks per buyback
    /// @return totalBuybackBNB_ Total BNB used for buybacks
    /// @return avgBNBPerBuyback Average BNB per buyback
    function getStats() external view returns (
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
    ) {
        totalSupply_ = TOTAL_SUPPLY;
        circulatingSupply = totalSupply_ - burnedTokens;
        burnedTokens_ = burnedTokens;
        buybackTokensRemaining_ = buybackTokensRemaining;
        totalBuybackTokensSold_ = totalBuybackTokensSold;
        totalBuybackTokensBurned_ = totalBuybackTokensBurned;
        totalBuybacks_ = totalBuybacks;
        avgBlocksPerBuyback = (totalBuybacks == 0 || tradingStartBlock == 0)
            ? 0
            : (block.number - tradingStartBlock) / totalBuybacks;
        totalBuybackBNB_ = totalBuybackBNB;
        avgBNBPerBuyback = (totalBuybacks == 0) ? 0 : totalBuybackBNB / totalBuybacks;
    }

    /// @notice Allow contract to receive BNB
    receive() external payable {}
    
    /// @notice Block manual BNB withdrawal
    function withdraw() public pure {
        revert("Withdrawal of BNB is blocked");
    }

    // --- Events ---
    /// @notice Emitted on manual reserve burn
    event ManualReserveBurn(address indexed user, uint256 amount, uint256 totalBurned);
    /// @notice Emitted on burn progress update
    event BurnProgressUpdated(uint256 totalBurned, uint256 percentBurned);
    /// @notice Emitted on each progressive sale for BNB
    event ProgressiveSale(uint256 tokensSold, uint256 bnbReceived, uint256 accumulatedBNB);
    /// @notice Emitted when a buyback is triggered
    event BuybackTriggered(address indexed user, uint256 bnbAmount, uint256 timestamp);
    /// @notice Emitted when tokens are burned via buyback
    event BuybackBurn(uint256 tokensBurned, uint256 bnbUsed, uint256 totalBurned);

    uint256 public totalBuybacks;
    uint256 public totalBuybackBNB;

    /// @notice Approve router for token spending
    function approveRouter() external onlyOwner {
        _approve(address(this), address(pancakeRouter), type(uint256).max);
    }
}