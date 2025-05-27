// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/VaultonToken.sol";

contract DeployVaulton is Script {
    function run() external {
        // Load private key and PancakeSwap Router address from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address pancakeRouter = vm.envAddress("PANCAKE_ROUTER");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Vaulton Token contract
        Vaulton vaulton = new Vaulton(pancakeRouter);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed contract address
        console2.log("Vaulton Token deployed at:", address(vaulton));
    }
}