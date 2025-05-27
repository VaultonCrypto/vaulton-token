// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract MockFactory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        pair = address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);
        return pair;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function feeTo() external pure returns (address) {
        return address(0);
    }

    function feeToSetter() external pure returns (address) {
        return address(0);
    }

    function setFeeTo(address) external {}
    
    function setFeeToSetter(address) external {}
}