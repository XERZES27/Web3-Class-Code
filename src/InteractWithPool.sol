// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../compoundContracts/CometInterface.sol";
import "./IWETH9.sol";
import "../compoundContracts/CometRewards.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {console} from "forge-std/Test.sol";


interface IFaucet{
    function drip(address token) external;
}

contract InteractFromPool {
    address public constant COMP = 0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531;
    address public constant WBTC = 0xa035b9e130F2B1AedC733eEFb1C67Ba4c503491F;
    address public constant cbETH = 0xb9fa8F5eC3Da13B508F462243Ad0555B46E028df;
    address public constant USDCBase = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant WETH = 0x2D5ee574e710219a521449679A4A7f2B43f046ad;
    uint256 public constant MAX_COMP_SUPPLY = 20000000000000000000; // 20 COMP
    WETH9 public constant iWETH = WETH9(WETH);
    IFaucet public ifaucet; 
    CometRewards public rewards;
    CometInterface public comet;
    IERC20 public interfaceCOMP;
    string[5] supportedTokens = ["COMP","WBTC","cbETH","USDCBase","WETH"];
    address public constant RewardsAddr = 0x8bF5b658bdF0388E8b482ED51B14aef58f90abfD;
    address public constant COMETPROXY = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;
    
    mapping(address user => USER) public userMap;
    mapping( string name=>address token) public tokenNameMap;

    constructor() {
        comet = CometInterface(COMETPROXY);
        interfaceCOMP = IERC20(COMP);
        rewards = CometRewards(RewardsAddr);
        ifaucet =  IFaucet(0x68793eA49297eB75DFB4610B68e076D2A5c7646C);
        ifaucet.drip(COMP);
        ifaucet.drip(WBTC);
        ifaucet.drip(cbETH);
        ifaucet.drip(USDCBase);
        tokenNameMap["COMP"]=COMP;
        tokenNameMap["WBTC"]=WBTC;
        tokenNameMap["cbETH"]=cbETH;
        tokenNameMap["USDCBase"]=USDCBase;
        tokenNameMap["WETH"]=WETH;
    }

    receive() external payable {}
    fallback() external payable { 
    }



    function getSupportedTokens()public view returns(string[5] memory){
        return supportedTokens ;
    }

    function getTokenAddress(string memory name)public view returns(address tokenAddress){
        return tokenNameMap[name];
    }

    function getBaseToken() public view returns (address) {
        return comet.baseToken();
    }

    function getCOMPEquivalentToNativeETH(uint256 amount)public view  returns(uint256){
        uint256 priceOfComp = getPrice(COMP);
        uint256 priceOfWETH = getPrice(WETH);
        return (priceOfWETH*amount*comet.baseScale())/priceOfComp;
    }

    function supplyCollateralInNativeEth() external  payable {
        iWETH.deposit{value:msg.value}();
        iWETH.approve(address(comet), msg.value); //approval given to comet proxy for moving WETH

        comet.supplyTo(address(this), address(iWETH), msg.value);
        if(userMap[msg.sender].collateralBalance[address(iWETH)]==0){
            userMap[msg.sender].suppliedCollaterAssets.push(address(iWETH));
        }
        userMap[msg.sender].collateralBalance[address(iWETH)] += msg.value;
    }

    function supplyCollateralByAsset(address asset,uint256 amount) external {
        IERC20(asset).approve(address(comet), amount); 
        comet.supplyTo(address(this), asset, amount);
        if(userMap[msg.sender].collateralBalance[asset]==0){
            userMap[msg.sender].suppliedCollaterAssets.push(asset);

        }
        userMap[msg.sender].collateralBalance[asset] += amount;
        
    }

    function BalanceCheck()  public view returns (uint256) {
        return address(this).balance;
    }

    function getCOMPBalance()public view returns (uint256){
        return interfaceCOMP.balanceOf(address(this));
    }
    function getSupportedTokenBalance(string memory tokenName)public view returns (uint256){
        return IERC20(tokenNameMap[tokenName]).balanceOf(address(this));
    }

    function isBorrowAllowed()  public view returns (bool) {
        return comet.isBorrowCollateralized(msg.sender);
    }

    function isLiquidatable()  public view returns (bool) {
        return comet.isLiquidatable(msg.sender);
    }

    function getPrice(address asset)   public view returns (uint256) {
        return comet.getPrice(comet.getAssetInfoByAddress(asset).priceFeed);
    }

    function getBaseTokenPrice()  public view returns (uint256) {
        return comet.getPrice(comet.baseTokenPriceFeed()) / comet.baseScale();
    }

    function getAssetScale(address asset)   public view returns (uint64) {
        return comet.getAssetInfoByAddress(asset).scale;
    }

    function getValueOfAllCollateralizedAssetsE8()  public view returns (uint256) {
        uint256 valueOfCollateralizedAssets = 0;

        for (uint256 i = 0; i < userMap[msg.sender].suppliedCollaterAssets.length; i++) {
            address collateralizedAsset = userMap[msg.sender].suppliedCollaterAssets[i];
            valueOfCollateralizedAssets +=
                getPrice(collateralizedAsset) * userMap[msg.sender].collateralBalance[collateralizedAsset];
        }
        return valueOfCollateralizedAssets / 1e18;
    }

    function getShareOfCollateralToPoolE18(address collateral) public view returns (uint256) {
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

    function getPercentageOfBorrowedAmountToCollateralE6() public view returns (uint256) {
        return ((userMap[msg.sender].totalBorrowedAmount * 1e10) / getValueOfAllCollateralizedAssetsE8());
    }

    function BuyCollateral(address _asset) public {
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

    function getWithDrawedAmount() public view returns (uint256) {
        return userMap[msg.sender].totalBorrowedAmount;
    }

    function getCollateralizedAssets() public view returns (address[] memory) {
        return userMap[msg.sender].suppliedCollaterAssets;
    }

    function getSuppleAPR() public view returns (uint64) {
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



