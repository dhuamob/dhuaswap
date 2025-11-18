// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Pair
 * @dev Implements the storage layout and liquidity-minting logic for LP tokens.
 *      Burn/Swap will be implemented in later steps.
 */
contract Pair {
    string public constant name = "DhuaSwap LP Token";
    string public constant symbol = "DHUA-LP";
    uint8 public constant decimals = 18;

    uint256 private constant MINIMUM_LIQUIDITY = 1_000;
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of the most recent liquidity event

    uint256 private unlocked = 1;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    error Locked();
    error ZeroAddress();
    error InsufficientInputAmount();
    error InsufficientLiquidityMinted();
    error InsufficientBalance();

    modifier lock() {
        if (unlocked != 1) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(address _token0, address _token1) {
        if (_token0 == address(0) || _token1 == address(0)) revert ZeroAddress();
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    // --- ERC20-like functionality for LP tokens ------------------------------------------------

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= value, "PAIR: INSUFFICIENT_ALLOWANCE");
            allowance[from][msg.sender] = allowed - value;
        }
        _transfer(from, to, value);
        return true;
    }

    // --- Liquidity view helpers ---------------------------------------------------------------

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    // --- Core AMM logic (partial) -------------------------------------------------------------

    /**
     * @notice Mints LP tokens based on token amounts already sent to the pair.
     * @param to Recipient of the LP tokens.
     */
    function mint(address to) external lock returns (uint256 liquidity) {
        if (to == address(0)) revert ZeroAddress();

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        if (amount0 == 0 || amount1 == 0) revert InsufficientInputAmount();

        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // lock minimum liquidity
        } else {
            liquidity = _min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);

        _update(
            _toUint112(balance0),
            _toUint112(balance1),
            uint32(block.timestamp % 2 ** 32)
        );
        kLast = uint256(reserve0) * reserve1;

        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice Burns LP tokens and sends underlying assets to `to`.
     * @dev Caller must transfer LP tokens to this contract before calling.
     */
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        if (to == address(0)) revert ZeroAddress();

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply;
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityMinted();

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(
            _toUint112(balance0),
            _toUint112(balance1),
            uint32(block.timestamp % 2 ** 32)
        );
        kLast = uint256(reserve0) * reserve1;

        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @notice Core swap logic (fee configurable via constants).
     * @param amount0Out Amount of token0 to send to `to`
     * @param amount1Out Amount of token1 to send to `to`
     * @param to Recipient address
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, "PAIR: INSUFFICIENT_OUTPUT");
        require(amount0Out == 0 || amount1Out == 0, "PAIR: ONE_SIDE_ONLY"); // only one can be nonzero
        require(to != address(0), "PAIR: INVALID_TO");

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "PAIR: INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > (_reserve0 - amount0Out) ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > (_reserve1 - amount1Out) ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "PAIR: INSUFFICIENT_INPUT");

        // Adjusted constant product check: charge fee on input
        uint256 balance0Adjusted = (balance0 * FEE_DENOMINATOR) - (amount0In * (FEE_DENOMINATOR - FEE_NUMERATOR));
        uint256 balance1Adjusted = (balance1 * FEE_DENOMINATOR) - (amount1In * (FEE_DENOMINATOR - FEE_NUMERATOR));
        require(
            balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * (FEE_DENOMINATOR**2),
            "PAIR: K"
        );

        _update(_toUint112(balance0), _toUint112(balance1), uint32(block.timestamp % 2 ** 32));
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // --- Internal helpers ---------------------------------------------------------------------

    function _transfer(address from, address to, uint256 value) internal {
        if (to == address(0)) revert ZeroAddress();
        uint256 fromBalance = balanceOf[from];
        if (fromBalance < value) revert InsufficientBalance();
        unchecked {
            balanceOf[from] = fromBalance - value;
        }
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        // Allow minimum liquidity lock to address(0) only for MINIMUM_LIQUIDITY
        if (to == address(0) && value != MINIMUM_LIQUIDITY) revert ZeroAddress();
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        if (from == address(0)) revert ZeroAddress();
        uint256 fromBalance = balanceOf[from];
        if (fromBalance < value) revert InsufficientBalance();
        unchecked {
            balanceOf[from] = fromBalance - value;
        }
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "PAIR: TRANSFER_FAILED");
    }

    function _update(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) internal {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
        emit Sync(_reserve0, _reserve1);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
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

    function _toUint112(uint256 value) private pure returns (uint112) {
        require(value <= type(uint112).max, "PAIR: OVERFLOW");
        return uint112(value);
    }
}

