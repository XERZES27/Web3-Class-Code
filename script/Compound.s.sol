// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {InteractFromPool} from "../src/InteractWithPool.sol";

contract CometScript is Script {
    address public constant USDCAddr =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant COMP = 0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531;
    InteractFromPool MainContract;
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MainContract = new InteractFromPool(
            COMP,
            0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e
        );
        vm.stopBroadcast();
    }
}

