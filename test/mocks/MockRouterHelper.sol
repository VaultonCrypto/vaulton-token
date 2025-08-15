// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITestUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockRouterHelper is ITestUniswapV2Router02 {
    address public immutable override WETH;
    address private _factory;

    constructor() {
        // These will be ignored in the test as we're using etch to override
        WETH = address(0);
        _factory = address(0);
    }
    
    // Special implementation for tests that guarantees ETH transfer
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address to,
        uint256
    ) external override {
        require(path.length >= 2, "Invalid path");
        require(to != address(0), "Invalid address");
        
        // Always transfer tokens from sender to this contract
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        
        // Always send 1 ETH to guarantee the test passes
        uint256 ethToSend = 1 ether;
        
        // Send ETH to receiver
        (bool success,) = to.call{value: ethToSend}("");
        require(success, "ETH transfer failed");
    }

    // Stub implementations for other required interface functions
    function swapExactTokensForETH(uint256, uint256, address[] calldata, address, uint256) external pure override returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        return amounts;
    }

    function addLiquidity(address, address, uint256, uint256, uint256, uint256, address, uint256) external pure override returns (uint256, uint256, uint256) {
        return (0, 0, 0);
    }
    
    function addLiquidityETH(address, uint256, uint256, uint256, address, uint256) external payable override returns (uint256, uint256, uint256) {
        return (0, 0, 0);
    }
    
    function factory() external view override returns (address) {
        return _factory;
    }

    function getAmountOut(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function getAmountIn(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function getAmountsOut(uint256, address[] calldata) external pure override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function getAmountsIn(uint256, address[] calldata) external pure override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function quote(uint256, uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function removeLiquidity(address, address, uint256, uint256, uint256, address, uint256) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityETH(address, uint256, uint256, uint256, address, uint256) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(address, uint256, uint256, uint256, address, uint256) external pure override returns (uint256) {
        return 0;
    }

    function removeLiquidityETHWithPermit(address, uint256, uint256, uint256, address, uint256, bool, uint8, bytes32, bytes32) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address, uint256, uint256, uint256, address, uint256, bool, uint8, bytes32, bytes32) external pure override returns (uint256) {
        return 0;
    }

    function removeLiquidityWithPermit(address, address, uint256, uint256, uint256, address, uint256, bool, uint8, bytes32, bytes32) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function swapETHForExactTokens(uint256, address[] calldata, address, uint256) external payable override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function swapExactETHForTokens(uint256, address[] calldata, address, uint256) external payable override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256, address[] calldata, address, uint256) external payable override {}

    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external pure override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256, uint256, address[] calldata, address, uint256) external pure override {}

    function swapTokensForExactETH(uint256, uint256, address[] calldata, address, uint256) external pure override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }

    function swapTokensForExactTokens(uint256, uint256, address[] calldata, address, uint256) external pure override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        return amounts;
    }
}
