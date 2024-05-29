// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface  WETH9 {


    function deposit() external payable ;
    function withdraw(uint wad) external ;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool) ;

    function transfer(address dst, uint wad) external returns (bool) ;

    function transferFrom(address src, address dst, uint wad)external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}
