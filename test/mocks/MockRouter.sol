// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./ITestUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // Added this import

contract MockRouter is ITestUniswapV2Router02 {
    address private immutable _WETH;
    address private immutable _FACTORY;

    uint256 public reserveToken = 5_000_000 * 1e18; // 5M VAULTON in pool
    uint256 public reserveETH = 1000 ether; // 1000 BNB in pool (~$300k liquidity)

    bool public forceRevert;
    uint256 public slippagePercent = 50; // Default slippage 0.5%
    uint256 public feePercent = 25; // PancakeSwap fee 0.25%

    address[] private defaultPath;
    bool private pathSet = false;

    uint256 public tokensReceived;
    uint256 public bnbReceived;

    constructor(address weth_, address factory_) {
        require(weth_ != address(0), "MockRouter: zero WETH");
        require(factory_ != address(0), "MockRouter: zero factory");
        _WETH = weth_;
        _FACTORY = factory_;
    }

    function setReserves(uint256 _reserveToken, uint256 _reserveETH) public {
        reserveToken = _reserveToken;
        reserveETH = _reserveETH;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserveToken, reserveETH);
    }

    function WETH() external view override returns (address) {
        return _WETH;
    }

    function factory() external view returns (address) {
        return _FACTORY;
    }

    // Correction: function can be pure, not view
    function getPair(address, address) external pure returns (address) {
        // Always returns the same pair for test simplification
        return address(0xBEEF);
    }

    function setForceRevert(bool _force) external {
        forceRevert = _force;
    }

    // Required interface implementations with removed parameter names
    function quote(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external override {}

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 /* amountOutMin */,
        address[] calldata path,
        address to,
        uint256 /* deadline */
    ) external override {
        require(!forceRevert, "Token to BNB swap failed");
        require(path.length >= 2, "MockRouter: path too short");
        require(amountIn > 0, "MockRouter: INSUFFICIENT_INPUT_AMOUNT");
        
        IERC20 token = IERC20(path[0]);
        require(token.allowance(msg.sender, address(this)) >= amountIn, "MockRouter: insufficient allowance");
        
        token.transferFrom(msg.sender, address(this), amountIn);

        // Realistic price calculation with impact
        uint256 ethAmount = getAmountOutWithImpact(amountIn, reserveToken, reserveETH);
        
        // Update reserves to simulate real AMM
        reserveToken += amountIn;
        reserveETH -= ethAmount;
        
        require(ethAmount > 0, "MockRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(ethAmount <= address(this).balance, "MockRouter: insufficient BNB balance");
        
        (bool sent, ) = to.call{value: ethAmount}("");
        require(sent, "MockRouter: ETH transfer failed");
    }

    function swapExactETHForTokens(
        uint256,
        address[] calldata,
        address,
        uint256
    ) external payable override returns (uint256[] memory) {
        return new uint256[](0);
    }

    event SwapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    );

    function addLiquidityETH(
        address,
        uint256 amountTokenDesired,
        uint256,
        uint256,
        address,
        uint256
    ) external payable override returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        // Simulate adding liquidity
        reserveToken += amountTokenDesired;
        reserveETH += msg.value;

        // Return the added amounts
        return (amountTokenDesired, msg.value, 1);
    }

    // Minimal implementations
    function getAmountOut(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function getAmountIn(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata /*path*/) external pure override returns (uint256[] memory) {
        // Return a simulated output array with 2 values
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn * 2; // Simulate 2x price for testing
        return amounts;
    }

    function getAmountsIn(uint256, address[] calldata) external pure override returns (uint256[] memory) {
        return new uint256[](0);
    }

    // Empty implementation stubs
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external pure override returns (uint256) {
        return 0;
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bool,
        uint8,
        bytes32,
        bytes32
    ) external pure override returns (uint256) {
        return 0;
    }

    function swapTokensForExactTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external pure override returns (uint256[] memory) {
        return new uint256[](0);
    }

    // Additional required implementations
    function addLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external pure override returns (uint256, uint256, uint256) {
        return (0, 0, 0);
    }

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityETH(
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityETHWithPermit(
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bool,
        uint8,
        bytes32,
        bytes32
    ) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityWithPermit(
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bool,
        uint8,
        bytes32,
        bytes32
    ) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function swapETHForExactTokens(
        uint256,
        address[] calldata,
        address,
        uint256
    ) external payable override returns (uint256[] memory) {
        return new uint256[](0);
    }

    function swapExactTokensForETH(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external pure override returns (uint256[] memory) {
        return new uint256[](0);
    }

    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external pure override returns (uint256[] memory) {
        return new uint256[](0);
    }

    function swapTokensForExactETH(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external pure override returns (uint256[] memory) {
        return new uint256[](0);
    }

    /**
     * @notice Set a default path to use when the provided path is invalid
     * @dev This function is used by tests to ensure a valid path is always available
     * @param _path The path array containing token addresses (must have at least 2 elements)
     */
    function setPath(address[] memory _path) external {
        require(_path.length >= 2, "MockRouter: path too short");
        defaultPath = new address[](_path.length);
        for (uint i = 0; i < _path.length; i++) {
            defaultPath[i] = _path[i];
        }
        pathSet = true;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256, // amountOutMin
        address[] calldata path,
        address to,
        uint256 // deadline
    ) external payable override {
        require(!forceRevert, "BNB to token swap failed");
        require(path.length >= 2, "MockRouter: path too short");
        require(msg.value > 0, "MockRouter: no ETH sent");
        
        // Realistic buyback calculation
        uint256 tokenAmount = getAmountOutWithImpact(msg.value, reserveETH, reserveToken);
        
        // Update reserves
        reserveETH += msg.value;
        reserveToken -= tokenAmount;
        
        if (to == 0x000000000000000000000000000000000000dEaD) {
            // Buyback to burn - simulate token burn
            tokensReceived += tokenAmount;
        } else {
            // Regular swap - would need token transfer in real scenario
            // For mock, just track the amount
            tokensReceived += tokenAmount;
        }
        
        bnbReceived += msg.value;
    }

    /// @notice Set realistic market conditions
    /// @param _slippage Slippage percentage (basis points, ex: 50 = 0.5%)
    /// @param _fee Trading fee percentage (basis points, ex: 25 = 0.25%)
    function setMarketConditions(uint256 _slippage, uint256 _fee) external {
        slippagePercent = _slippage;
        feePercent = _fee;
    }

    /// @notice Simulate price impact based on trade size
    /// @param amountIn Amount being traded
    /// @param reserveIn Input token reserve
    /// @param reserveOut Output token reserve
    function getAmountOutWithImpact(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256) {
        // Apply trading fee
        uint256 amountInWithFee = (amountIn * (10000 - feePercent)) / 10000;
        
        // Calculate output with AMM formula: x * y = k
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        
        // Apply additional slippage for large trades
        uint256 tradeImpact = (amountIn * 10000) / reserveIn;
        if (tradeImpact > 100) { // >1% of pool
            uint256 extraSlippage = tradeImpact / 20; // 0.05% per 1% of pool
            amountOut = (amountOut * (10000 - extraSlippage)) / 10000;
        }
        
        return amountOut;
    }

    /// @notice Simulate CEX trading volume and arbitrage
    /// @param volumeBNB Daily trading volume to simulate
    function simulateCEXVolume(uint256 volumeBNB) external {
        // Simulate price variations from CEX arbitrage
        uint256 priceVariation = (volumeBNB / 100) % 500; // Max 5% variation
        
        if (priceVariation > 0) {
            // Randomly adjust reserves to simulate price movement
            if (block.timestamp % 2 == 0) {
                reserveETH = (reserveETH * (10000 + priceVariation)) / 10000;
            } else {
                reserveETH = (reserveETH * (10000 - priceVariation)) / 10000;
            }
        }
    }

    /// @notice Reset reserves to initial mainnet-like conditions
    function resetToMainnetConditions() external {
        reserveToken = 5_000_000 * 1e18; // 5M VAULTON
        reserveETH = 1000 ether; // 1000 BNB
        slippagePercent = 50; // 0.5%
        feePercent = 25; // 0.25%
    }

    receive() external payable {}
}