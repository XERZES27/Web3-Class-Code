// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../compoundContracts/CometInterface.sol";
import "../compoundContracts/CometRewards.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {console} from "forge-std/Test.sol";

interface IWETH is IERC20 {
    function withdraw(uint256) external;
    function deposit() external payable;
}

struct USER {
    uint256 supply;
    uint256 totalBorrowedAmount;
    mapping(address collateralAsset => uint256 collateralizedAmmount) collateralBalance;
    bool canBorrow;
    uint256 allowedBorrowAmount;
    address[] suppliedCollaterAssets;
}

contract InteractFromPool {
    CometRewards public rewards;
    CometInterface public comet;
    IERC20 public interfaceCOMP;
    address public constant USDCBase = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant RewardsAddr = 0x8bF5b658bdF0388E8b482ED51B14aef58f90abfD;
    mapping(address user => USER) userMap;

    constructor(address _assetAddress, address _cometProxy) {
        comet = CometInterface(_cometProxy);
        interfaceCOMP = IERC20(_assetAddress);
        rewards = CometRewards(RewardsAddr);
    }

    receive() external payable {}

    function getBaseToken() public view returns (address) {
        return comet.baseToken();
    }

    function supplyCollateral() public payable {
        // Supply collateral
        // uint256 eth1000=1000000000000000000000;
        uint256 amount = msg.value;
        uint256 amountSupply = amount - 1e18; // supply amount should have room for some gas

        interfaceCOMP.approve(address(comet), amountSupply); //approval given to comet proxy for moving COMP

        console.log("balance before supply");
        // console.log(comet.balanceOf(address(this)));

        console.log(IERC20(interfaceCOMP).balanceOf(address(this)));
        comet.supplyTo(address(this), address(interfaceCOMP), amountSupply);
        if(userMap[msg.sender].collateralBalance[address(interfaceCOMP)]==0){
            userMap[msg.sender].suppliedCollaterAssets.push(address(interfaceCOMP));
        }
        userMap[msg.sender].collateralBalance[address(interfaceCOMP)] += amountSupply;
        console.log("balance post supply");
        console.log(comet.collateralBalanceOf(msg.sender, address(interfaceCOMP)));
        console.log(IERC20(interfaceCOMP).balanceOf(address(this)));
        // comet.collateralBalanceOf(, address(interfaceWETH));
        //supply cometProxy with the wETH to increase collateral position

        // 100000000000
        // 90000000000
    }

    function supplyCollateralByAsset(address asset) external payable {
        // Supply collateral
        // uint256 eth1000=1000000000000000000000;
        uint256 amount = msg.value;
        uint256 amountSupply = (amount * 9) / 10; // supply amount should have room for some gas
        IERC20(asset).approve(address(comet), amountSupply); //approval given to comet proxy for moving COMP
        comet.supplyTo(address(this), asset, amountSupply);
        if(userMap[msg.sender].collateralBalance[asset]==0){
            userMap[msg.sender].suppliedCollaterAssets.push(asset);

        }
        userMap[msg.sender].collateralBalance[asset] += amountSupply;
        
    }

    function BalanceCheck() public returns (uint256) {
        return address(this).balance;
    }

    function isBorrowAllowed() public returns (bool) {
        return comet.isBorrowCollateralized(msg.sender);
    }

    function isLiquidatable() public returns (bool) {
        return comet.isLiquidatable(msg.sender);
    }

    function getPrice(address asset) public returns (uint256) {
        return comet.getPrice(comet.getAssetInfoByAddress(asset).priceFeed);
    }

    function getBaseTokenPrice() public returns (uint256) {
        return comet.getPrice(comet.baseTokenPriceFeed()) / comet.baseScale();
    }

    function getAssetScale(address asset) public returns (uint64) {
        return comet.getAssetInfoByAddress(asset).scale;
    }

    function getValueOfAllCollateralizedAssetsE8() public returns (uint256) {
        uint256 valueOfCollateralizedAssets = 0;

        for (uint256 i = 0; i < userMap[msg.sender].suppliedCollaterAssets.length; i++) {
            address collateralizedAsset = userMap[msg.sender].suppliedCollaterAssets[i];
            valueOfCollateralizedAssets +=
                getPrice(collateralizedAsset) * userMap[msg.sender].collateralBalance[collateralizedAsset];
        }
        return valueOfCollateralizedAssets / 1e18;
    }

    function getShareOfCollateralToPoolE18(address collateral) public returns (uint256) {
        uint256 valueOfCollateralizedAssets = 0;
        uint256 sizeOfCollateral = 0;

        for (uint256 i = 0; i < userMap[msg.sender].suppliedCollaterAssets.length; i++) {
            address collateralizedAsset = userMap[msg.sender].suppliedCollaterAssets[i];
            uint256 valueOfCollateralizedAsset =
                getPrice(collateralizedAsset) * userMap[msg.sender].collateralBalance[collateralizedAsset];

            valueOfCollateralizedAssets += valueOfCollateralizedAsset;

            if (collateral == collateralizedAsset) {
                sizeOfCollateral = valueOfCollateralizedAsset;
            }
        }
        return ((sizeOfCollateral * 1e20) / valueOfCollateralizedAssets);
    }

    function getPercentageOfBorrowedAmountToCollateralE8() public returns (uint256) {
        return ((userMap[msg.sender].totalBorrowedAmount * 1e10) / getValueOfAllCollateralizedAssetsE8());
    }

    function BuyCollateral(address _asset, uint256 usdcAmount) public {
        IERC20(USDCBase).transferFrom(tx.origin, address(this), 10e11);
        console.log(IERC20(USDCBase).balanceOf(address(this)));
        IERC20(USDCBase).approve(address(comet), 10e10);
        comet.buyCollateral(_asset, 0, 1, msg.sender);
    }

    function WithdrawAsset(uint256 _amount) public {
        console.log(address(this).balance);
        // comet.priceScale();
        comet.withdraw(address(interfaceCOMP), _amount); // currently withdrawing  wETH incase of a different asset will be considered as borrowing
            // interfaceCOMP.transfer(address(this),_amount); //withdrawl from wETH to ETH into this contract
            // console.log(address(this).balance);
            // msg.sender.call{value:_amount}(""); //Eth back to msg.sender
            // comet.collateralBalanceOf(address(this), address(interfaceWETH));
    }

    function BorrowAsset(address _asset, uint256 _amount) public {
        //Borrow USDC from collateral provided in COMP during initialising
        // console.log(msg.sender);
        // console.log(IERC20(_asset).balanceOf(address(this))); // balance check for USDC = 0
        // console.log(comet.getCollateralReserves(_asset));
        // console.log(comet.isBorrowCollateralized(msg.sender));
        comet.withdrawTo(msg.sender, _asset, _amount); // withdrawing USDC based on COMP supplied as collateral
        userMap[msg.sender].totalBorrowedAmount += _amount;
        // comet.borrowBalanceOf(msg.sender);

        // IERC20(_asset).transfer(msg.sender, _amount);

        // console.log(IERC20(_asset).balanceOf(address(this))); // borrowed USDC updates the balance
    }

    function getCollateralizedAmountByAsset(address _asset) public view returns (uint256) {
        return userMap[msg.sender].collateralBalance[_asset];
    }

    function getWithDrawedAmount(address _asset) public view returns (uint256) {
        return userMap[msg.sender].totalBorrowedAmount;
    }

    function getCollateralizedAssets() public view returns (address[] memory) {
        return userMap[msg.sender].suppliedCollaterAssets;
    }

    function getSuppleAPR() public returns (uint64) {
        uint256 util = comet.getUtilization();
        return comet.getSupplyRate(util);
    }

    function getBorrowAPR() public returns (uint256) {
        uint256 util = comet.getUtilization();
        // console.log(util);
        uint64 borrowRate = comet.getBorrowRate(util);
        // console.log(borrowRate);
        uint256 APR = (borrowRate * 864 * 365) / 1e13;
        console.log("balance before accrual");
        console.log(IERC20(address(interfaceCOMP)).balanceOf(tx.origin));
        comet.accrueAccount(tx.origin);
        CometRewards.RewardOwed memory rewardDetails = rewards.getRewardOwed(address(comet), tx.origin);
        console.log("Owed amount and token address");
        console.log(rewardDetails.owed);
        console.log(rewardDetails.token);

        // console.log(IERC20(address(interfaceCOMP)).balanceOf(address(this)));
        console.log("APR");
        console.log(APR);
        return APR;
    }
}
