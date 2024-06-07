// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CPAMM } from "../src/CPAMM.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";

contract TestCPAMM is Test {

    CPAMM cpamm;
    ERC20Mock token0;
    ERC20Mock token1;
    uint public constant INITIAL_BALANCE = 100 ether;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");

    function setUp() external{

        vm.startPrank(deployer);
        token0 = new ERC20Mock("token0","t1",deployer,INITIAL_BALANCE);
        token1 = new ERC20Mock("token1","t2",deployer,INITIAL_BALANCE);

        token0.mint(user, INITIAL_BALANCE);
        cpamm = new CPAMM(address(token0), address(token1));

        vm.stopPrank(); 
    }

    function test_addLiquidity() public {
        
        vm.startPrank(deployer);
        token0.approve(address(cpamm),10 ether);
        token1.approve(address(cpamm),20 ether);

        console.log(token0.allowance(deployer, address(cpamm)));
        console.log(token1.allowance(deployer, address(cpamm)));
        uint share = cpamm.addLiquidity(10 ether, 20 ether);


        console.log(share);
        assertEq(token0.balanceOf(address(cpamm)), 10 ether);
        assertEq(token1.balanceOf(address(cpamm)), 20 ether);
        assertEq(share, 14142135623730950488);
        vm.stopPrank();
       
    }

    function test__swap() public {

        vm.startPrank(deployer);
        token0.approve(address(cpamm),10 ether);
        token1.approve(address(cpamm),20 ether);

        console.log(token0.allowance(deployer, address(cpamm)));
        console.log(token1.allowance(deployer, address(cpamm)));
        uint share = cpamm.addLiquidity(10 ether, 20 ether);
        vm.stopPrank();

        vm.startPrank(user);
        token0.approve(address(cpamm),20 ether);
        uint amountOut =cpamm.swap(address(token0), 20 ether);
        console.log(amountOut);
       assertEq(token1.balanceOf(user), amountOut);

    }

    function test__removeLiquidity() public {
        vm.startPrank(deployer);
        token0.approve(address(cpamm),10 ether);
        token1.approve(address(cpamm),20 ether);

        console.log(token0.allowance(deployer, address(cpamm)));
        console.log(token1.allowance(deployer, address(cpamm)));
        uint share = cpamm.addLiquidity(10 ether, 20 ether);
        console.log(share);
        (uint val1,uint val2) = cpamm.removeLiquidity(share);
        console.log("value 1", val1);
        console.log("value 2", val2);
        vm.stopPrank();

    }
}