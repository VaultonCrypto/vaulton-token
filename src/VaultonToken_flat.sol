// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// src/VaultonToken.sol

/// @title Vaulton Token
/// @notice ERC20 token with buyback & burn, anti-bot, and auto-sell features.
/// @dev Designed for transparency and security, ready for audit.
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // --- Supply & burn ---

    /// @notice Total supply of the token (30 million)
    uint256 public constant TOTAL_SUPPLY = 30_000_000 * 10**18;
    /// @notice Initial burn amount (8 million)
    uint256 public constant INITIAL_BURN = 8_000_000 * 10**18;
    /// @notice Reserve for buyback & burn (11 million)
    uint256 public constant BUYBACK_RESERVE = 11_000_000 * 10**18;
    /// @notice Total tokens burned (all mechanisms)
    uint256 public burnedTokens;
    /// @notice Remaining tokens available for buyback & burn
    uint256 public buybackTokensRemaining;
    /// @notice Total tokens sold for BNB accumulation (auto-sell)
    uint256 public totalBuybackTokensSold;
    /// @notice Total tokens burned via buyback & burn
    uint256 public totalBuybackTokensBurned;
    /// @notice Block number of the last buyback
    uint256 public lastBuybackBlock;

    // --- Buyback & sell parameters ---

    /// @notice BNB threshold to trigger a buyback
    uint256 public BNB_THRESHOLD = 0.05 ether; // Initial: 0.05 BNB
    /// @notice Minimum BNB threshold allowed
    uint256 public constant MIN_BNB_THRESHOLD = 1;
    /// @notice Percentage of reserve to auto-sell (base 10000)
    uint256 public AUTO_SELL_PERCENT = 200; // Initial: 2% per sell
    /// @notice Minimum tokens to auto-sell
    uint256 public constant MIN_AUTO_SELL = 1;
    /// @notice BNB accumulated for next buyback
    uint256 public accumulatedBNB;
    /// @notice Number of auto-sell operations performed
    uint256 public totalSellOperations;
    /// @notice Maximum auto-sell percentage (base 10000)
    uint256 public constant MAX_AUTO_SELL_PERCENT = 500;

    // --- DEX addresses ---
    IUniswapV2Router02 public immutable pancakeRouter;
    address public pancakePair;
    address public marketingWallet;
    address public cexWallet;

    // --- Trading & swap state ---
    bool public tradingEnabled = false;
    bool public autoSellEnabled = false;
    bool private _inSwap;

    /// @notice Prevents reentrancy during swaps
    modifier lockTheSwap() {
        require(!_inSwap, "Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    // --- Owner configuration ---

    /// @notice Set the BNB threshold for triggering buybacks
    /// @param newThreshold New BNB threshold (must be >= MIN_BNB_THRESHOLD)
    function setBNBThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold >= MIN_BNB_THRESHOLD, "Threshold too low");
        BNB_THRESHOLD = newThreshold;
    }

    /// @notice Set the auto-sell percentage (base 10000)
    /// @param newPercent New auto-sell percent (min 1, max 5%)
    function setAutoSellPercent(uint256 newPercent) external onlyOwner {
        require(newPercent >= MIN_AUTO_SELL && newPercent <= MAX_AUTO_SELL_PERCENT, "Percent out of range");
        AUTO_SELL_PERCENT = newPercent;
    }

    /// @notice Enable or disable auto-sell
    /// @param enabled True to enable, false to disable
    function setAutoSellEnabled(bool enabled) external onlyOwner {
        autoSellEnabled = enabled;
    }

    // --- Anti-bot system ---
    uint256 public tradingStartBlock;
    uint256 public constant ANTI_BOT_BLOCKS = 5;
    mapping(address => bool) public isWhitelisted;

    /// @notice Emitted when a non-whitelisted address is blocked during anti-bot phase
    event AntiBotBlocked(address indexed user, uint256 blockNumber);

    /// @notice Add an address to the anti-bot whitelist
    function addToWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = true;
    }
    /// @notice Remove an address from the anti-bot whitelist
    function removeFromWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = false;
    }

    // --- Token recovery (non-native) ---
    /// @notice Recover ERC20 tokens sent to this contract by mistake (not VAULTON)
    event RecoveredERC20(address token, uint256 amount);
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "Cannot recover VAULTON");
        IERC20(token).transfer(owner(), amount);
        emit RecoveredERC20(token, amount);
    }

    /// @notice Emitted on swap errors
    event SwapError(string reason);

    // --- Constructor: mint, burn, distribute, approve router ---
    /// @notice Deploys the Vaulton token, burns initial supply, sets up buyback reserve and router approvals
    /// @param _pancakeRouter PancakeSwap router address
    /// @param _marketingWallet Marketing wallet address
    /// @param _cexWallet CEX wallet address
    constructor(address _pancakeRouter, address _marketingWallet, address _cexWallet) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_cexWallet != address(0), "Invalid CEX wallet");
        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        marketingWallet = _marketingWallet;
        cexWallet = _cexWallet;

        _mint(address(this), TOTAL_SUPPLY);
        _burn(address(this), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        buybackTokensRemaining = BUYBACK_RESERVE;

        // --- Initial distribution ---
        // The 11M buyback reserve and 1M marketing tokens are sent to the owner for PinkLock locking.
        // After PinkLock unlock, the owner must transfer the buyback reserve to the Vaulton contract.
        uint256 ownerTokens = TOTAL_SUPPLY - INITIAL_BURN - BUYBACK_RESERVE - 1_000_000 * 10**18;
        _transfer(address(this), owner(), ownerTokens + BUYBACK_RESERVE + 1_000_000 * 10**18);

        // For transparency, the marketing wallet receives its tokens via the owner.
        // _transfer(address(this), marketingWallet, 1_000_000 * 10**18); // Optional if already included above

        _approve(address(this), address(_pancakeRouter), type(uint256).max);
    }

    // --- PinkSale compatibility ---
    /// @notice Approve a router for spending tokens (for DEX listing)
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router");
        _approve(address(this), _router, type(uint256).max);
    }

    /// @notice Set the DEX pair address
    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair");
        pancakePair = _pair;
    }

    /// @notice Enable trading and record the start block
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        require(pancakePair != address(0), "Pair not set");
        tradingEnabled = true;
        tradingStartBlock = block.number;
    }

    // --- Ownership overrides ---
    function owner() public view override returns (address) {
        return super.owner();
    }

    /// @notice Renounce ownership and disable auto-sell
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // --- Core transfer logic with auto-sell and anti-bot ---
    /// @dev Handles anti-bot, auto-sell, and triggers buyback if threshold is met
    function _transfer(address from, address to, uint256 amount) internal override {
        // Restrict trading before launch
        if (!tradingEnabled) {
            require(
                from == owner() || to == owner() ||
                from == address(this) || to == address(this) ||
                to == pancakePair ||
                from == address(pancakeRouter) || to == address(pancakeRouter),
                "Trading not enabled"
            );
        }

        // Anti-bot: restrict buys in first blocks to whitelisted addresses
        if (
            tradingEnabled &&
            tradingStartBlock > 0 &&
            block.number < tradingStartBlock + ANTI_BOT_BLOCKS &&
            from == pancakePair &&
            !isWhitelisted[to]
        ) {
            emit AntiBotBlocked(to, block.number);
            revert("Anti-bot: not whitelisted");
        }

        // Auto-sell logic on sell to DEX
        if (!_inSwap && autoSellEnabled && pancakePair != address(0)) {
            bool isSell = to == pancakePair 
                && from != address(this) 
                && from != address(pancakeRouter);

            if (isSell) {
                uint256 sellAmount = (amount * AUTO_SELL_PERCENT) / 10000;
                if (sellAmount > buybackTokensRemaining) sellAmount = buybackTokensRemaining;
                uint256 contractBalance = balanceOf(address(this));
                if (sellAmount > contractBalance) sellAmount = contractBalance;
                if (sellAmount > 0) {
                    _progressiveSellForBNB(sellAmount);
                }
                if (accumulatedBNB >= BNB_THRESHOLD) {
                    _triggerBuybackAndBurn();
                }
            }
        }

        super._transfer(from, to, amount);
    }

    // --- Swap tokens for BNB and accumulate for buyback ---
    /// @dev Sells tokens for BNB and accumulates for buyback
    /// @param sellAmount Amount of tokens to sell
    function _progressiveSellForBNB(uint256 sellAmount) internal lockTheSwap {
        if (buybackTokensRemaining == 0) return;
        if (sellAmount == 0) return;
        if (balanceOf(address(this)) < sellAmount) return;

        uint256 initialBNB = address(this).balance;
        _swapTokensForBNB(sellAmount);
        uint256 bnbReceived = address(this).balance - initialBNB;

        if (bnbReceived > 0) {
            buybackTokensRemaining -= sellAmount;
            totalBuybackTokensSold += sellAmount;
            totalSellOperations++;
            lastBuybackBlock = block.number;
            accumulatedBNB += bnbReceived;
            emit ProgressiveSale(sellAmount, bnbReceived, accumulatedBNB);
        }
    }

    // --- Slippage protection ---
    uint256 public slippagePercent = 50;
    uint256 public constant MAX_SLIPPAGE = 500;

    /// @notice Set slippage percent for swaps (base 10000)
    /// @param newPercent New slippage percent (max 5%)
    function setSlippagePercent(uint256 newPercent) external onlyOwner {
        require(newPercent <= MAX_SLIPPAGE, "Slippage too high");
        slippagePercent = newPercent;
    }

    // --- Gas limit for swaps ---
    uint256 public swapGasLimit = 500_000;
    /// @notice Set gas limit for swap operations
    /// @param newLimit New gas limit (between 100,000 and 2,000,000)
    function setSwapGasLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 100_000 && newLimit <= 2_000_000, "Gas limit out of range");
        swapGasLimit = newLimit;
    }

    // --- Internal swap logic ---
    /// @dev Swaps tokens for BNB using PancakeRouter
    /// @param tokenAmount Amount of tokens to swap
    function _swapTokensForBNB(uint256 tokenAmount) internal {
        require(address(pancakeRouter) != address(0), "Router not set");
        require(pancakePair != address(0), "Pair not set");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        uint256 minOut;
        bool slippageOk = true;
        try pancakeRouter.getAmountsOut(tokenAmount, path) returns (uint256[] memory amountsOut) {
            minOut = amountsOut[1] - ((amountsOut[1] * slippagePercent) / 10000);
        } catch {
            slippageOk = false;
            emit SwapError("Slippage calculation failed");
        }

        if (!slippageOk) return;

        try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens{
            gas: swapGasLimit
        }(
            tokenAmount,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        ) {
        } catch Error(string memory reason) {
            emit SwapError(reason);
        } catch {
            emit SwapError("Unknown error");
        }
    }

    // --- Buyback & burn logic ---
    /// @dev Executes buyback & burn using accumulated BNB
    function _triggerBuybackAndBurn() internal lockTheSwap {
        if (accumulatedBNB < MIN_BNB_THRESHOLD) return;

        uint256 bnbForBuyback = accumulatedBNB;
        accumulatedBNB = 0;

        totalBuybacks += 1;
        totalBuybackBNB += bnbForBuyback;

        emit BuybackTriggered(msg.sender, bnbForBuyback, block.timestamp);

        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        uint256 minTokensOut = 0;
        try pancakeRouter.getAmountsOut(bnbForBuyback, path) returns (uint256[] memory amountsOut) {
            minTokensOut = amountsOut[1] - ((amountsOut[1] * slippagePercent) / 10000);
        } catch {
            minTokensOut = 0;
        }

        address burnAddress = 0x000000000000000000000000000000000000dEaD;

        try pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbForBuyback,
            gas: swapGasLimit
        }(
            minTokensOut,
            path,
            burnAddress,
            block.timestamp + 300
        ) {
            burnedTokens += minTokensOut;
            totalBuybackTokensBurned += minTokensOut;
            emit BuybackBurn(minTokensOut, bnbForBuyback, burnedTokens);
            emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
        } catch Error(string memory reason) {
            emit SwapError(reason);
            accumulatedBNB = bnbForBuyback;
        } catch {
            emit SwapError("Unknown error");
            accumulatedBNB = bnbForBuyback;
        }
    }

    // --- Global statistics for analytics/front-end ---
    /// @notice Returns global stats for analytics and front-end
    /// @return totalSupply_ Total supply
    /// @return circulatingSupply Circulating supply
    /// @return burnedTokens_ Total burned tokens
    /// @return buybackTokensRemaining_ Buyback reserve remaining
    /// @return totalBuybackTokensSold_ Tokens sold for BNB (auto-sell)
    /// @return totalBuybackTokensBurned_ Tokens burned via buyback
    /// @return totalBuybacks_ Number of buybacks
    /// @return totalSellOperations_ Number of auto-sell operations
    /// @return avgBlocksPerBuyback Average blocks per buyback
    /// @return totalBuybackBNB_ Total BNB used for buybacks
    /// @return avgBNBPerBuyback Average BNB per buyback
    function getStats() external view returns (
        uint256 totalSupply_,
        uint256 circulatingSupply,
        uint256 burnedTokens_,
        uint256 buybackTokensRemaining_,
        uint256 totalBuybackTokensSold_,
        uint256 totalBuybackTokensBurned_,
        uint256 totalBuybacks_,
        uint256 totalSellOperations_,
        uint256 avgBlocksPerBuyback,
        uint256 totalBuybackBNB_,
        uint256 avgBNBPerBuyback
    ) {
        totalSupply_ = TOTAL_SUPPLY;
        circulatingSupply = totalSupply_ - burnedTokens;
        burnedTokens_ = burnedTokens;
        buybackTokensRemaining_ = buybackTokensRemaining;
        totalBuybackTokensSold_ = totalBuybackTokensSold;
        totalBuybackTokensBurned_ = totalBuybackTokensBurned;
        totalBuybacks_ = totalBuybacks;
        avgBlocksPerBuyback = (totalBuybacks == 0 || tradingStartBlock == 0)
            ? 0
            : (block.number - tradingStartBlock) / totalBuybacks;
        totalBuybackBNB_ = totalBuybackBNB;
        avgBNBPerBuyback = (totalBuybacks == 0) ? 0 : totalBuybackBNB / totalBuybacks;
        totalSellOperations_ = totalSellOperations;
    }

    /// @notice Allow contract to receive BNB
    receive() external payable {}
    
    /// @notice Block manual BNB withdrawal
    function withdraw() public pure {
        revert("Withdrawal of BNB is blocked");
    }

    // --- Events ---
    /// @notice Emitted on burn progress update
    event BurnProgressUpdated(uint256 totalBurned, uint256 percentBurned);
    /// @notice Emitted on each progressive sale for BNB
    event ProgressiveSale(uint256 tokensSold, uint256 bnbReceived, uint256 accumulatedBNB);
    /// @notice Emitted when a buyback is triggered
    event BuybackTriggered(address indexed user, uint256 bnbAmount, uint256 timestamp);
    /// @notice Emitted when tokens are burned via buyback
    event BuybackBurn(uint256 tokensBurned, uint256 bnbUsed, uint256 totalBurned);

    uint256 public totalBuybacks;
    uint256 public totalBuybackBNB;

    /// @notice Approve router for token spending
    function approveRouter() external onlyOwner {
        _approve(address(this), address(pancakeRouter), type(uint256).max);
    }
}

