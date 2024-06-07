# CPAMM (Constant Product Automated Market Maker) Smart Contract

## Overview

CPAMM is a decentralized automated market maker (AMM) contract implemented in Solidity. It allows users to add liquidity, swap tokens, and remove liquidity while maintaining a constant product formula \( x \cdot y = k \).

## Features

- **Token Swaps**: Swap between two ERC20 tokens with a 0.3% fee.
- **Liquidity Management**: Add and remove liquidity to the pool.
- **Invariant Preservation**: Ensures the product of the reserves remains constant.

## Requirements

- Solidity ^0.8.24
- Foundry (for testing)

## Contract Structure

### State Variables

- `IERC20 public immutable token0`: The first token in the pair.
- `IERC20 public immutable token1`: The second token in the pair.
- `uint public reserve0`: The reserve of the first token.
- `uint public reserve1`: The reserve of the second token.
- `uint public totalSupply`: The total supply of liquidity tokens.
- `mapping(address => uint) public balanceOf`: Tracks the balance of liquidity tokens for each user.

### Modifiers

- `modifier MoreThanZero(uint amount)`: Ensures the input amount is greater than zero.

### Constructor

```solidity
constructor(address _token0, address _token1) {
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
}
```

Initializes the contract with the given token addresses.

### Functions

#### `mint(address _to, uint _amount) private`

Mints `_amount` liquidity tokens to the address `_to`.

#### `burn(address _to, uint _amount) private`

Burns `_amount` liquidity tokens from the address `_to`.

#### `_update(uint _reserve0, uint _reserve1) private`

Updates the reserves with the new values `_reserve0` and `_reserve1`.

#### `swap(address _tokenIn, uint _amountIn) external MoreThanZero(_amountIn) returns (uint _amountOut)`

Swaps `_amountIn` of `_tokenIn` for the other token and returns the output amount.

#### `addLiquidity(uint _amount0, uint _amount1) external returns (uint shares)`

Adds liquidity to the pool, mints liquidity tokens, and returns the amount of shares minted.

#### `removeLiquidity(uint _shares) external returns (uint amount0, uint amount1)`

Removes liquidity from the pool, burns liquidity tokens, and returns the amounts of tokens withdrawn.

#### `_sqrt(uint256 y) private pure returns (uint256 z)`

Calculates the square root of `y`.

#### `_min(uint256 x, uint256 y) private pure returns (uint256)`

Returns the minimum of `x` and `y`.

## Deployment

1. Deploy the contract by providing the addresses of the two tokens.
2. Interact with the contract through its functions to swap tokens, add liquidity, and remove liquidity.

## Testing

The contract is tested using Foundry. Ensure you have Foundry installed and set up. Run the tests with:

```bash
forge test
```

## License

This project is licensed under the MIT License.