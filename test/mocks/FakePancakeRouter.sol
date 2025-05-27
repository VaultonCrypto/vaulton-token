// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FakePancakeRouter {
    address public immutable WETH;
    address public immutable factory;
    
    constructor(address _weth, address _factory) {
        WETH = _weth;
        factory = _factory;
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 /* amountOutMin */,
        address[] calldata /* path */,
        address /* to */,
        uint256 /* deadline */
    ) external payable returns (bool) {
        return true;
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 /* amountIn */,
        uint256 /* amountOutMin */,
        address[] calldata /* path */,
        address /* to */,
        uint256 /* deadline */
    ) external pure returns (bool) {
        return true;
    }
    
    function addLiquidityETH(
        address /* token */,
        uint256 amountTokenDesired,
        uint256 /* amountTokenMin */,
        uint256 /* amountETHMin */,
        address /* to */,
        uint256 /* deadline */
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    ) {
        return (amountTokenDesired, msg.value, amountTokenDesired);
    }
}
