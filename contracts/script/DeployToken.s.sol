// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ERC20.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        TestToken token = new TestToken("Dhua Token", "DHUA", 1_000_000 ether);

        vm.stopBroadcast();

        console.log("Token deployed at:", address(token));
    }
}


