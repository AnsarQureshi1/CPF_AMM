//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./IERC20.sol";

error CPAMM__InvalidToken();
error CPAMM__MoreThanZero();

contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;


    uint public reserve0;
    uint public reserve1;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;

    modifier MoreThanZero(uint amount) {
        require(amount > 0, "More Than Zero");
        _;
    }

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function burn(address _to, uint _amount) private {
        balanceOf[_to] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(
        address _tokenIn,
        uint _amountIn
    ) external MoreThanZero(_amountIn) returns (uint _amountOut) {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "More Than Zero"
        );

        

        bool isToken0 = _tokenIn == address(token0);
        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint reserveIn,
            uint reserveOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);


        tokenIn.transferFrom(msg.sender,address(this),_amountIn);

        uint amountInWithFee = (_amountIn * 997 ) / 1000;

        /**
           X.Y = K
           (X + DX) (Y - DY) = K
           Y - DY = K / X + DX 
           Y - K / X + DX  = DY
           Y - XY / X + DX = DY 
           Y(X+DX) - XY  / X + DX = DY
           YX + YDX -XY / X+DX = DY
           YDX / X + DX
         */
        _amountOut = (reserveOut  * amountInWithFee) / (reserveIn + amountInWithFee);
        tokenOut.transfer(msg.sender, _amountOut);
        _update(token0.balanceOf(address(this)),token1.balanceOf(address(this)));

    }


    function addLiquidity(uint _amount0, uint _amount1) external returns(uint shares){
        token0.transferFrom(msg.sender,address(this), _amount0);
        token1.transferFrom(msg.sender,address(this), _amount1);

        // xy = k
        // x / y = (x + dx ) / (y + dy) want to prove for the liquidity
        /*
         X (Y + DY) = Y (X + DX)
         XY + XDY  = XY + YDX
         SUBTRACTING XY ON BOTH SIDE   
         XDY = XY + YDX
         DY = XY + YDX / X       
         DY = Y/X * DX
         DY / DX = Y / X     
         DY * X = Y * DX  { DY => TOKEN1 IN || DX => TOKEN0 IN  || Y => RESERVE1 || X => RESERVE0 }
         ^=> THIS CONDITION MUST SATISFY FOR ADDING LIQUIDITY
        */
        if(reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount0 == reserve1 * _amount1, "x/y != dx/dy");
        }


        // L0 = f(x,y)
        // L1 = f(dx,dy)
        // T = total share
        // s = share to Mint

        // L1 / L0 = (T + S) / T 
        // L1 * T = l0 (T+S)
        // L1 *T = L0 * T + L0 * S
        // L1 *T - L0 * T  = L0 * S
        // (L1 - L0) T = L0 * S
        // (L1 - L0) T / L0 = S
        // (L1 - L0) T / L0 = S
        // (L1 - L0) T / L0 = DX / X = DY / Y
        
        /*
        --- Equation 1 ---
        (L1 - L0) / L0 = (sqrt((x + dx)(y + dy)) - sqrt(xy)) / sqrt(xy)
         DX / DY = X / Y
         DY = DX (Y/X)

        --- Equation 2 ---
        Equation 1 = sqrt((xy + xdy + ydx + dydx) - sqrt(xy)) / sqrt(xy)
                     sqrt(xy+ x (dx * y /x)) + ydx + (dx * y /x)) dx) -- sqrt(xy)) / sqrt(xy) => putting dy value in this
                     sqrt((xy + 2ydx + dx^2 * y/x) -sqrt(xy)) / sqrt(xy)
                     multiply and divide by sqrt(x)
                     sqrt(x^2.y + 2xydx + dx^2 * y) - sqrt(x^2.y) / sqrt(x^2.y)
                     taking sqrt(y) common

                     sqrt(y) * sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2) / (sqrt(y) sqrt(x^2)
                     sqrt(y) is cancell out

        
        --- Equation 3 ---
        Equation2 = sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2) / (sqrt(y)) sqrt(x^2)
                    sqrt(x+dx)^2 -sqrt(x^2) / sqrt(x^2)
                    x + dx - x / x
                    dx / x
                    
        */    

        if(totalSupply == 0 ){
            shares = _sqrt(_amount0 * _amount1);

        } else {
            shares = _min((_amount0 * totalSupply) / reserve0 , (_amount1 * totalSupply) / reserve1);
        }

        require( shares > 0, "shares = 0");
        mint(msg.sender,shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));


    }

    function removeLiquidity(uint _shares) external returns(uint amount0, uint amount1){
         /*
        Claim
        dx, dy = amount of liquidity to remove
        dx = s / T * x
        dy = s / T * y

        Proof
        Let's find dx, dy such that
        v / L = s / T
        
        where
        v = f(dx, dy) = sqrt(dxdy)
        L = total liquidity = sqrt(xy)
        s = shares
        T = total supply

        --- Equation 1 ---
        v = s / T * L
        sqrt(dxdy) = s / T * sqrt(xy)

        Amount of liquidity to remove must not change price so 
        dx / dy = x / y

        replace dy = dx * y / x
        sqrt(dxdy) = sqrt(dx * dx * y / x) = dx * sqrt(y / x)

        Divide both sides of Equation 1 with sqrt(y / x)
        dx = s / T * sqrt(xy) / sqrt(y / x)
           = s / T * sqrt(x^2) = s / T * x

        Likewise
        dy = s / T * y
        */
        
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0 ) / totalSupply;
        amount1 = (_shares * bal1 ) / totalSupply;

        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        burn(msg.sender,_shares);

        _update(bal0 - amount0, bal1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

    }


    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }


}
