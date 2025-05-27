// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITestUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // Ajout de cet import

contract MockRouter is ITestUniswapV2Router02 {
    address private immutable _WETH;
    address private immutable _FACTORY;

    uint256 public reserveToken;
    uint256 public reserveETH;

    bool public forceRevert;

    address[] private defaultPath;
    bool private pathSet = false;

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

    function factory() external view override returns (address) {
        return _FACTORY;
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256,
        address[] calldata,
        address,
        uint256
    ) external payable override {}

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint /*amountOutMin*/,
        address[] calldata path,
        address to,
        uint /*deadline*/
    ) external override {
        require(!forceRevert, "Token to BNB swap failed");
        require(path.length >= 2, "MockRouter: path too short");
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint256 ethAmount = 1 ether; // Simule un swap

        // Envoie l'ETH au destinataire
        (bool sent, ) = to.call{value: ethAmount}("");
        require(sent, "Token to BNB swap failed");
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
        // Simuler l'ajout de liquidité
        reserveToken += amountTokenDesired;
        reserveETH += msg.value;

        // Retourner les montants ajoutés
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

    function swapExactETHForTokens(
        uint256,
        address[] calldata,
        address,
        uint256
    ) external payable override returns (uint256[] memory) {
        return new uint256[](0);
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

    receive() external payable {}
}