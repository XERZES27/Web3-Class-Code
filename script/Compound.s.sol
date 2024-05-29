// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
// import {StdCheatsSafe} from "forge-std/StdCheats.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import {InteractFromPool} from "../src/InteractWithPool.sol";

// interface IFaucet{
//     function drip(address token) external;
// }

interface IPool {
    function supplyCollateral() external payable;
    function getCollateralizedAssets() external view returns (address[] memory);
    function getCOMPBalance() external returns (uint256);
    function getValueOfAllCollateralizedAssetsE8() external returns (uint256);
}

contract PoolScript is Script {
    IPool public ipool;
    function setUp() public {
        ipool = IPool(0xA495Dcf031463E1CcDD47f240a50aC89066Ca741);
    }

    function run() public {
        // ipool.supplyCollateral{value:952153625602241377}();
        console.log(ipool.getValueOfAllCollateralizedAssetsE8());
        console.log(ipool.getCOMPBalance());
        // console.log(ipool.getCollateralizedAssets());
    }
}

contract CometScript is Script {
    address public constant USDCAddr =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant COMP = 0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531;
    InteractFromPool MainContract;
    // IFaucet public ifaucet;
    function setUp() public {
        // ifaucet = IFaucet(0x68793eA49297eB75DFB4610B68e076D2A5c7646C);
    }

    function run() public {
        vm.startBroadcast();
        // ifaucet.drip(COMP);
        console.log(IERC20(COMP).balanceOf(msg.sender));
        MainContract = new InteractFromPool(
            
        );
        // MainContract.supplyCollateral{value: 952153625602241377}();
        console.log("getValueOfAllCollateralizedAssetsE8");
        console.log(MainContract.getValueOfAllCollateralizedAssetsE8());
        vm.stopBroadcast();
    }
}
