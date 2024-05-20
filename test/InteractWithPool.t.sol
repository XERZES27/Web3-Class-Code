// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {LendingPoolSetup} from "../src/CompoundMain.sol";
import {InteractFromPool} from "../src/InteractWithPool.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

// uint256 eth1000=1000000000000000000000;
contract CometTest is Test {
    InteractFromPool public MainContract;
    address public constant USDCAddr = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant COMP = 0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531;
    address public constant WETH = 0x2D5ee574e710219a521449679A4A7f2B43f046ad;
    address private constant accountMain = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private constant collateralBuyer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function setUp() public {
        // vm.startPrank(CompAccount);
        vm.startPrank(accountMain, accountMain);
        // MainContract=new LendingPoolSetup(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e,0xc28aD44975C614EaBe0Ed090207314549e1c6624);
        MainContract = new InteractFromPool(COMP, 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e);
        //1st address is the supplyAsset
        //2nd address is the baseAsset proxy (USDC from compound)
    }

    function test_supply() public {
        // MainContract.setFactory()

        // vm.startPrank(collateralBuyer);
        // deal(USDCAddr,collateralBuyer, 10e12);
        // IERC20(USDCAddr).approve(address(MainContract), 10e11);
        // MainContract.BuyCollateral(COMP, 10e10);

        deal(COMP, address(MainContract), 10e21);

        // console.log(IERC20(COMP).balanceOf(address(MainContract)));
        MainContract.supplyCollateral{value: 10e21}();
        console.log(IERC20(USDCAddr).balanceOf(accountMain));

        MainContract.BorrowAsset(USDCAddr, 10e7);
        // for(uint256 i=0; i<105;i++){
        //     skip(31536000);
        // }

        MainContract.getBorrowAPR();

        console.log(IERC20(USDCAddr).balanceOf(accountMain));
        MainContract.isLiquidatable();

        console.log("======get price of asset");
        console.log(MainContract.getPrice(WETH)/1e8);

        //Borrow USDC using Compound supply provided above
    }
    ///forge-config: default.invariant.runs = 2
    ///forge-config: default.invariant.depth = 2
    function invariant_test_supplyCollateral() public {
        // -- snip --
        deal(COMP, address(MainContract), 10e19);
        MainContract.supplyCollateral{value: 10e19}();
        assertEq(MainContract.getCollateralizedAmountByAsset(COMP), 10e19 - 1e18);
        deal(WETH, address(MainContract), 1000);
        MainContract.supplyCollateralByAsset{value: 1000}(WETH);
        assertEq(MainContract.getCollateralizedAmountByAsset(WETH), (1000 * 9) / 10);
    }

    function run() public {}
}
//anvil --fork-url https://rpc.ankr.com/eth_sepolia/287fee8f199099ac482368d6765c7e03dbe94caa769b24d429d01e8c730de674
//forge test --match-contract CometTest --fork-url http://127.0.0.1:8545 -vvvv
