// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FakeWETH {
    function deposit() external payable {}

    function withdraw(uint256 amount) external {}

    function balanceOf(address /* account */) external pure returns (uint256) {
        return 1e18; // Fake balance
    }
}
