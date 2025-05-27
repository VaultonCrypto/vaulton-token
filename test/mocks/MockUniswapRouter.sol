// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Make the contract abstract since we won't implement all interface functions
abstract contract MockUniswapRouter is IUniswapV2Router02 {
    address private immutable _factory;
    address private immutable _WETH;
    
    constructor(address factory_, address WETH_) {
        _factory = factory_;
        _WETH = WETH_;
    }
    
    function factory() external pure override returns (address) {
        return address(0); // Remplace par la vraie adresse si besoin
    }
    
    function WETH() external pure override returns (address) {
        return address(0); // Remplace par la vraie adresse si besoin
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external override {}
    
    function addLiquidityETH(
        address,
        uint256 amountTokenDesired,
        uint256,
        uint256,
        address,
        uint256
    ) external payable override returns (uint256, uint256, uint256) {
        return (amountTokenDesired, msg.value, amountTokenDesired);
    }
}
