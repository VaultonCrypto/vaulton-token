// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 >=0.6.2 ^0.8.0 ^0.8.19;

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

// lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

/**
 * @title Vaulton Token
 * @dev Implementation of the Vaulton Token with burn mechanism, taxes, and BNB distribution
 * @author Vaulton Team
 * @notice This token implements a burn mechanism that removes taxes once 75% of supply is burned
 */
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // Constants
    /// @notice Total supply of VAULTON tokens (50 million)
    /// @dev This is the maximum amount of tokens that will ever exist
    uint256 public constant TOTAL_SUPPLY = 50_000_000 * 10**18;

    /// @notice Amount of tokens burned at contract deployment (15 million)
    /// @dev This represents 30% of total supply burned immediately upon launch
    uint256 public constant INITIAL_BURN = 15_000_000 * 10**18;

    /// @notice Threshold at which taxes are automatically and permanently removed
    /// @dev Set to 75% of total supply (37.5 million tokens including initial burn)
    /// @dev Once reached, buyTax and sellTax are set to 0% forever
    uint256 public constant BURN_THRESHOLD = (TOTAL_SUPPLY * 75) / 100;

    /// @notice Maximum amount allowed in a single transaction (1% of total supply)
    /// @dev Applies to transfers between wallets (not DEX operations)
    /// @dev Prevents whale manipulation while allowing normal trading
    uint256 public constant MAX_TX_AMOUNT = TOTAL_SUPPLY / 100;

    // State variables

    /// @notice Total amount of tokens burned throughout the contract's lifetime
    /// @dev This counter is used to track progress toward the 75% burn threshold
    /// @dev When BURN_THRESHOLD is reached, all taxes are permanently disabled
    uint256 public burnedTokens;

    /// @notice Interface to the PancakeSwap V2 router for token swaps and liquidity operations
    /// @dev Used for converting accumulated tokens to BNB and adding liquidity
    IUniswapV2Router02 public pancakeRouter;

    /// @notice Address of the main trading pair (typically VAULTON/WBNB)
    /// @dev This pair is used for buy/sell tax calculations and swap operations
    /// @dev Set via setPancakePair() after launch or auto-detected via _detectAndSetupPair()
    address public pancakePair;

    // Wallets
    address public marketingWallet;
    address public cexWallet;
    address public operationsWallet;

    // Shares for distribution (total = 100%)
    uint256 public marketingShare = 45;
    uint256 public cexShare = 25;
    uint256 public operationsShare = 30;

    // Distribution queue
    mapping(address => uint256) public pendingDistributions;
    bool private distributionQueued;
    uint256 private lastDistributionBlock;
    uint256 private constant DISTRIBUTION_DELAY = 1;

    // Mappings
    mapping(address => bool) public isDexPair;
    mapping(address => bool) private isExcludedFromFees;
    bool private inSwapAndLiquify;
    bool public taxesRemoved;

    // Tax Constants
    uint256 public buyTax = 5;
    uint256 public sellTax = 10;

    /// @notice Percentage of each tax allocated to token burning (60%)
    /// @dev This is the primary deflationary mechanism of the token
    uint256 private constant BURN_PERCENT = 60;

    /// @notice Percentage of each tax allocated to marketing operations (25%)
    /// @dev These tokens are accumulated in contract and converted to BNB for distribution
    uint256 private constant MARKETING_PERCENT = 25;

    /// @notice Percentage of each tax allocated to liquidity provision (15%)
    /// @dev These tokens are automatically converted to BNB and added back to liquidity pool
    uint256 private constant LIQUIDITY_PERCENT = 15;

    /// @notice Maximum amount allowed in DEX-to-DEX transfers (0.5% of total supply)
    uint256 public maxDexToDexAmount = TOTAL_SUPPLY / 200;

    /// @notice Tracks last DEX-to-DEX transfer time for each address (cooldown mechanism)
    mapping(address => uint256) private lastDexToDexTime;

    /// @notice Cooldown period between DEX-to-DEX transfers (5 minutes)
    uint256 private constant DEX_TO_DEX_COOLDOWN = 300;

    /// @notice Whether automatic token swapping is enabled
    bool public swapEnabled = true;

    /// @notice Block number when trading was enabled
    uint256 private launchBlock;

    /// @notice Whether trading is enabled (prevents MEV bots before launch)
    bool public tradingEnabled = false;

    /// @notice Number of blocks with anti-bot protection after trading is enabled
    uint256 private constant ANTI_BOT_BLOCKS = 3;

    /// @notice Timestamp of contract deployment
    uint256 private deploymentTime;

    /**
     * @notice Emitted when tax is applied to a transaction
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Total amount of the transaction
     * @param taxAmount Amount of tax collected
     * @param taxType Type of tax applied (buy/sell/universal)
     */
    event TaxApplied(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, string taxType);
    
    /**
     * @notice Emitted when swap and liquify process completes
     * @param tokensSwapped Amount of tokens swapped for BNB
     * @param bnbReceived Amount of BNB received from swap
     * @param tokensIntoLiquidity Amount of tokens added to liquidity
     */
    event SwapAndLiquifyCompleted(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    
    /**
     * @notice Emitted when a DEX pair status is updated
     * @param pair Address of the DEX pair
     * @param status New status of the pair
     */
    event DexPairUpdated(address indexed pair, bool status);
    
    /**
     * @notice Emitted when taxes are removed after burn threshold is reached
     */
    event TaxesRemoved();
    
    /**
     * @notice Emitted when initial burn is completed
     * @param amount Amount of tokens burned initially
     * @param timestamp Time when the burn occurred
     */
    event InitialBurnCompleted(uint256 amount, uint256 timestamp);
    
    /**
     * @notice Emitted when a DEX pair is automatically detected
     * @param pair Address of the detected pair
     */
    event PairAutoDetected(address indexed pair);
    
    /**
     * @notice Emitted when burn progress is updated
     * @param burnedAmount Total amount burned
     * @param burnPercentage Percentage of total supply burned
     */
    event BurnProgressUpdated(uint256 burnedAmount, uint256 burnPercentage);
    
    /**
     * @notice Emitted when tax rates are updated
     * @param buyTax New buy tax percentage
     * @param sellTax New sell tax percentage
     */
    event TaxesUpdated(uint256 buyTax, uint256 sellTax);
    
    /**
     * @notice Emitted when max transaction amount is updated
     * @param maxTxAmount New maximum transaction amount
     */
    event MaxTransactionUpdated(uint256 maxTxAmount);
    
    /**
     * @notice Emitted when marketing contract is updated
     * @param oldContract Previous marketing contract address
     * @param newContract New marketing contract address
     */
    event MarketingContractUpdated(address indexed oldContract, address indexed newContract);
    
    /**
     * @notice Emitted when funds are distributed to wallets
     * @param marketingAmount Amount sent to marketing wallet
     * @param cexAmount Amount sent to CEX wallet
     * @param operationsAmount Amount sent to operations wallet
     */
    event FundsDistributed(uint256 marketingAmount, uint256 cexAmount, uint256 operationsAmount);
    
    /**
     * @notice Emitted when wallet addresses are updated
     * @param marketingWallet New marketing wallet address
     * @param cexWallet New CEX wallet address
     * @param operationsWallet New operations wallet address
     */
    event WalletsUpdated(address indexed marketingWallet, address indexed cexWallet, address indexed operationsWallet);
    
    /**
     * @notice Emitted when distribution shares are updated
     * @param marketingShare New marketing share percentage
     * @param cexShare New CEX share percentage
     * @param operationsShare New operations share percentage
     */
    event SharesUpdated(uint256 marketingShare, uint256 cexShare, uint256 operationsShare);

    /**
     * @notice Emitted when swap enabled status is updated
     * @param enabled New swap enabled status
     */
    event SwapEnabledUpdated(bool enabled);

    /**
     * @notice Emitted when trading is enabled
     * @param blockNumber Block number when trading was enabled
     */
    event TradingEnabled(uint256 blockNumber);

    /**
     * @notice Emitted when the contract is finalized and ownership is renounced
     * @param timestamp The timestamp when the contract was finalized
     */
    event ContractFinalized(uint256 timestamp);
    event OwnershipRenounced(uint256 timestamp);

    /**
     * @notice Prevents reentrancy attacks during swap and liquify operations
     * @dev Sets inSwapAndLiquify flag to prevent recursive calls to swap functions
     */
    modifier lockTheSwap() {
        require(!inSwapAndLiquify, "Swap locked");
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * @notice Automatically detects trading pair before executing function
     * @dev Ensures pair configuration is up-to-date before tax calculations
     */
    modifier detectPair() {
        _detectAndSetupPair();
        _;
    }

    /**
     * @dev Anti-MEV protection during launch
     * @notice Prevents bot contracts from trading in first 3 blocks after enableTrading()
     * @dev Blocks contract calls and proxy transactions during protection period
     */
    modifier antiBotProtection() {
        // Protection TEMPORAIRE seulement pendant les 3 premiers blocs
        if (tradingEnabled && block.number <= launchBlock + ANTI_BOT_BLOCKS) {
            require(!_isContract(msg.sender), "No contracts during launch");
            require(tx.origin == msg.sender, "No proxy calls during launch");
        }
        _;
    }

    /**
     * @notice Contract constructor initializes the token and sets up initial configuration
     * @dev Initializes wallets with owner address, which should be updated post-deployment
     * @param _pancakeRouter Address of the PancakeSwap router
     */
    constructor(
        address _pancakeRouter
    ) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        
        deploymentTime = block.timestamp;

        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        
        // Initialize wallets with owner address - must be updated after deployment
        // via updateWallets() with appropriate dedicated addresses
        marketingWallet = owner();
        cexWallet = owner();
        operationsWallet = owner();

        // Mint total supply to owner
        _mint(owner(), TOTAL_SUPPLY);
        
        // Initial burn
        _burn(owner(), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        
        emit InitialBurnCompleted(INITIAL_BURN, block.timestamp);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
    }

    /**
     * @notice Manually set the PancakeSwap pair address
     * @dev This function is specifically designed for PinkSale FairLaunch integration
     * @dev After PinkSale creates the liquidity pair, this function must be called
     * @dev to ensure the contract recognizes the official trading pair
     * @param _pair Address of the trading pair created by PinkSale
     */
    function setPancakePair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair address");
        require(pancakePair == address(0), "Pair already set");
        pancakePair = _pair;
        isDexPair[_pair] = true;
        emit DexPairUpdated(_pair, true);
    }

    /**
     * @dev Attempts to automatically detect and set up the trading pair
     * @dev This mechanism is a fallback that tries to discover the pair if not set manually
     * @dev For PinkSale launches, manual configuration via setPancakePair() is recommended
     * @dev as it provides stronger guarantees about which pair is the official one
     */
    function _detectAndSetupPair() internal {
        if (pancakePair != address(0)) return;

        address factory = pancakeRouter.factory();
        address pair = IUniswapV2Factory(factory).getPair(
            address(this), 
            pancakeRouter.WETH()
        );
        
        if (pair != address(0)) {
            pancakePair = pair;
            isDexPair[pair] = true;
            emit PairAutoDetected(pair);
            emit DexPairUpdated(pair, true);

            // Auto-approve router for future swaps
            _approve(address(this), address(pancakeRouter), type(uint256).max);
        }
    }

    /**
     * @dev Wrapper function for pair detection that can be called internally
     * @dev This provides a cleaner way to trigger pair detection from other functions
     */
    function autoPairDetection() internal {
        _detectAndSetupPair();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Auto-detection of the pair
        autoPairDetection();

        // Check if burn threshold is reached
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @dev Override of the ERC20 transfer function to implement tax mechanism
     * @dev Handles taxation, burn, marketing allocation and liquidity management
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Amount of tokens being transferred
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override antiBotProtection { // ← AJOUTER LE MODIFIER ICI
        // Handle self-transfer first
        if (from == to) {
            super._transfer(from, to, amount);
            return;
        }

        // Cache frequently used values
        bool isExcludedFrom = isExcludedFromFees[from];
        bool isExcludedTo = isExcludedFromFees[to];
        bool isDexPairTo = isDexPair[to];
        bool isDexPairFrom = isDexPair[from];

        // Check max transaction limit
        if (!isExcludedFrom && !isExcludedTo && !isDexPairFrom && !isDexPairTo) {
            require(amount <= MAX_TX_AMOUNT, "Max tx");
        }

        // DEX-to-DEX abuse protection
        if (isDexPairFrom && isDexPairTo && from != address(0) && to != address(0)) {
            require(amount <= maxDexToDexAmount, "DEX transfer too large");
            require(
                lastDexToDexTime[from] == 0 || 
                block.timestamp >= lastDexToDexTime[from] + DEX_TO_DEX_COOLDOWN,
                "DEX transfer cooldown"
            );
            lastDexToDexTime[from] = block.timestamp;
        }

        uint256 taxAmount = 0;

        // Apply tax if applicable
        if (!isExcludedFrom && !isExcludedTo && !taxesRemoved) {
            if (isDexPairFrom && !isDexPairTo) {
                // BUY (DEX → Wallet) - Buy tax 5%
                taxAmount = (amount * buyTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "buy");
            } else if (!isDexPairFrom && isDexPairTo) {
                // SELL (Wallet → DEX) - Sell tax 10%
                taxAmount = (amount * sellTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "sell");
            } else if (!isDexPairFrom && !isDexPairTo) {
                // Transfer between wallets - Sell tax 10%
                taxAmount = (amount * sellTax) / 100;
                emit TaxApplied(from, to, amount, taxAmount, "transfer");
            }
            // DEX → DEX: No tax (but with protections)
        }

        // Calculate net amount to transfer
        uint256 sendAmount = amount - taxAmount;

        // Perform the net transfer (SINGLE TRANSFER ONLY!)
        super._transfer(from, to, sendAmount);

        // Handle taxes if any
        if (taxAmount > 0) {
            uint256 burnAmount = (taxAmount * BURN_PERCENT) / 100;
            uint256 marketingAmount = (taxAmount * MARKETING_PERCENT) / 100;
            uint256 liquidityAmount = taxAmount - burnAmount - marketingAmount;

            // Burn tokens directly from the sender
            if (burnAmount > 0) {
                _burn(from, burnAmount);
                burnedTokens += burnAmount;
            }

            // Transfer marketing amount to contract
            if (marketingAmount > 0) {
                super._transfer(from, address(this), marketingAmount);
            }

            // Handle liquidity
            if (liquidityAmount > 0) {
                super._transfer(from, address(this), liquidityAmount);

                if (swapEnabled && !inSwapAndLiquify && !isDexPair[from] && !isDexPair[to]) {
                    swapAndLiquify(liquidityAmount);
                }
            }
        }
    }

    /**
 * @notice Swaps tokens for BNB using PancakeSwap with slippage protection
 * @dev Includes 5% slippage protection to prevent frontrunning attacks
 * @dev This is a private function called during automatic liquidity operations
 * @param tokenAmount Amount of tokens to swap for BNB
 */
function swapTokensForBNB(uint256 tokenAmount) private {
    // Generate the Uniswap pair path of token -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    // Make sure the contract has allowed the router to spend these tokens
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // Protection against frontrunning
    uint256 minAmountOut = 0;
    if (pancakePair != address(0)) {
        try pancakeRouter.getAmountsOut(tokenAmount, path) returns (uint256[] memory amounts) {
            minAmountOut = amounts[1] * 95 / 100; // 5% slippage maximum
        } catch {
            // Fallback in case estimation fails
            minAmountOut = 0;
        }
    }

    uint256 initialBalance = address(this).balance;
    try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        minAmountOut, // Use the calculated minimum amount
        path,
        address(this),
        block.timestamp
    ) {
        // Swap succeeded
    } catch {
        revert("Token to BNB swap failed");
    }

    // Verify the amount of ETH received after the swap
    uint256 ethReceived = address(this).balance - initialBalance;
    require(ethReceived > 0, "No ETH received from swap");
}

/**
 * @notice Adds liquidity to the PancakeSwap pool
 * @dev Private function that pairs tokens with BNB for liquidity provision
 * @param tokenAmount Amount of tokens to add to liquidity pool
 * @param bnbAmount Amount of BNB to add to liquidity pool
 */
function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // Add the liquidity
    pancakeRouter.addLiquidityETH{value: bnbAmount}(
        address(this),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        owner(),
        block.timestamp
    );
}

    /**
 * @notice Automatically swaps accumulated tokens for BNB and adds to liquidity
 * @dev This function is called automatically during transactions when conditions are met
 * @dev Protected by lockTheSwap modifier to prevent reentrancy
 * @param contractTokenBalance Amount of tokens accumulated in the contract to swap
 */
function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    require(contractTokenBalance > 0, "No tokens to swap");

    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    uint256 initialBalance = address(this).balance;
    swapTokensForBNB(half);
    uint256 newBalance = address(this).balance - initialBalance;

    addLiquidity(otherHalf, newBalance);
    
    emit SwapAndLiquifyCompleted(half, newBalance, otherHalf);
}

    /**
 * @notice Manually triggers the swap of accumulated tokens to BNB and adds to liquidity
 * @param contractTokenBalance Amount of tokens to swap
 * @dev This function is called manually by the owner to convert accumulated taxes
 */
    function triggerSwapAndLiquify(uint256 contractTokenBalance) external onlyOwner {
        swapAndLiquify(contractTokenBalance);
    }

    /**
     * @notice Enable trading and start anti-bot protection
     * @dev Should be called after liquidity is added via PinkSale
     * @dev Starts 3-block protection period against MEV bots
     * @dev Can only be called once by owner
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        launchBlock = block.number;
        tradingEnabled = true;
        emit TradingEnabled(block.number);
    }

    /**
     * @notice Internal function to permanently remove all taxes when burn threshold is reached
     * @dev Automatically called when burnedTokens >= BURN_THRESHOLD (75% of total supply)
     * @dev Sets both buyTax and sellTax to 0% permanently - this action cannot be reversed
     * @dev Emits TaxesRemoved event to notify of this significant tokenomics change
     * @dev This creates a deflationary token that becomes fee-free once enough is burned
     * @dev SECURITY: Function is only called automatically, no manual override possible
     * @dev INVARIANT: taxesRemoved flag prevents duplicate execution
     */
    function _removeTaxes() internal {
        require(!taxesRemoved, "Taxes already removed");
        buyTax = 0;
        sellTax = 0;
        taxesRemoved = true;
        emit TaxesRemoved();
    }

    function renounceContract() external onlyOwner {
        renounceOwnership();
    }

    function excludeFromFees(address _address, bool _status) public onlyOwner {
        isExcludedFromFees[_address] = _status;
    }

    /**
     * @notice Exclude multiple accounts from fees
     * @param accounts Array of addresses to exclude
     * @param excluded True to exclude, false to include
     */
    function excludeMultipleAccountsFromFees(
        address[] memory accounts,
        bool excluded
    ) external onlyOwner {
        require(accounts.length > 0, "Empty array");
        for(uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Zero address");
            isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function setDexPair(address _pair, bool _status) external onlyOwner {
        isDexPair[_pair] = _status;
        emit DexPairUpdated(_pair, _status);
    }

    /**
     * @notice Returns current buy tax percentage
     * @return uint256 Current buy tax rate (0-100)
     */
    function getBuyTax() public view returns (uint256) {
        return buyTax;
    }

    /**
     * @notice Returns current sell tax percentage  
     * @return uint256 Current sell tax rate (0-100)
     */
    function getSellTax() public view returns (uint256) {
        return sellTax;
    }

    /**
     * @notice Manually burns tokens from a specific account
     * @dev Can only be called by owner, increments burnedTokens counter
     * @dev Will trigger automatic tax removal if burn threshold is reached
     * @param account Address from which to burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(address account, uint256 amount) external onlyOwner nonReentrant {
        require(account == address(this), "Can only burn from contract"); // ✅ BIEN
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _burn(account, amount);
        burnedTokens += amount;
        
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @notice Returns the total amount of tokens that have been burned
     * @return uint256 Total burned token amount
     */
    function getBurnedTokens() public view returns (uint256) {
        return burnedTokens;
    }

    /**
     * @notice Checks if an address is excluded from paying fees
     * @param _address The address to check
     * @return bool True if the address is excluded from fees
     */
    function isAddressExcludedFromFees(address _address) public view returns (bool) {
        return isExcludedFromFees[_address];
    }

    /**
     * @notice Returns the maximum amount allowed in a single transaction
     * @return uint256 Maximum transaction amount
     */
    function getMaxTransactionAmount() public pure returns (uint256) {
        return MAX_TX_AMOUNT;
    }

    /**
     * @notice External wrapper for excludeFromFees function
     * @dev Allows excluding addresses from fees through external calls
     * @param _address Address to exclude or include
     * @param _status True to exclude, false to include
     */
    function excludeFromFeesExternal(address _address, bool _status) external onlyOwner {
        excludeFromFees(_address, _status);
    }

    /**
     * @notice Prepares distribution of funds by calculating amounts for each wallet
     * @dev Creates a distribution queue that must be processed with distributeFunds()
     * @dev Enforces a block delay between distributions for security
     */
    function queueDistribution() public onlyOwner {
        require(address(this).balance > 0, "No funds to distribute");
        require(!distributionQueued, "Distribution already queued");
        require(block.number > lastDistributionBlock + DISTRIBUTION_DELAY, "Distribution delay not met");
        
        uint256 totalBalance = address(this).balance;
        
        pendingDistributions[marketingWallet] = (totalBalance * marketingShare) / 100;
        pendingDistributions[cexWallet] = (totalBalance * cexShare) / 100;
        pendingDistributions[operationsWallet] = (totalBalance * operationsShare) / 100;
        
        distributionQueued = true;
        lastDistributionBlock = block.number;
    }
    
    /**
     * @notice Processes the distribution of funds to a specific wallet
     * @dev Follows Check-Effects-Interactions pattern to prevent reentrancy issues
     * @param wallet Address of the wallet to receive funds
     */
    function processDistribution(address wallet) public nonReentrant onlyOwner {
        uint256 amount = pendingDistributions[wallet];
        require(amount > 0, "No funds queued for this wallet");
        
        // Update state before external interaction
        pendingDistributions[wallet] = 0;
        
        if (wallet == operationsWallet && 
            pendingDistributions[marketingWallet] == 0 && 
            pendingDistributions[cexWallet] == 0) {
            distributionQueued = false;
        }
        
        // External interaction last
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @notice Distributes accumulated BNB to configured wallets
     * @dev Distributes BNB according to percentages defined in marketingShare, cexShare and operationsShare
     */
    function distributeFunds() external onlyOwner {
        require(address(this).balance > 0, "No funds to distribute");
        
        queueDistribution();
        
        // Store values before zeroing them out
        uint256 marketingAmount = pendingDistributions[marketingWallet];
        uint256 cexAmount = pendingDistributions[cexWallet];
        uint256 operationsAmount = pendingDistributions[operationsWallet];
        
        processDistribution(marketingWallet);
        processDistribution(cexWallet);
        processDistribution(operationsWallet);
        
        // Emit event with correct amounts
        emit FundsDistributed(marketingAmount, cexAmount, operationsAmount);
    }
    
    /**
     * @notice Updates the wallet addresses for fund distribution
     * @dev Should be called after deployment to set up dedicated wallets
     * @param _marketingWallet Address of the marketing wallet
     * @param _cexWallet Address of the CEX wallet
     * @param _operationsWallet Address of the operations wallet
     */
    function updateWallets(
        address _marketingWallet,
        address _cexWallet,
        address _operationsWallet
    ) external onlyOwner {
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_cexWallet != address(0), "Invalid CEX wallet");
        require(_operationsWallet != address(0), "Invalid operations wallet");
        
        marketingWallet = _marketingWallet;
        cexWallet = _cexWallet;
        operationsWallet = _operationsWallet;
        
        emit WalletsUpdated(_marketingWallet, _cexWallet, _operationsWallet);
    }
    
    /**
     * @notice Updates the distribution shares for each wallet
     * @param _marketingShare Percentage for marketing wallet (out of 100)
     * @param _cexShare Percentage for CEX wallet (out of 100)
     * @param _operationsShare Percentage for operations wallet (out of 100)
     */
    function updateShares(
        uint256 _marketingShare,
        uint256 _cexShare,
        uint256 _operationsShare
    ) external onlyOwner {
        require(_marketingShare + _cexShare + _operationsShare == 100, "Shares must add up to 100");
        marketingShare = _marketingShare;
        cexShare = _cexShare;
        operationsShare = _operationsShare;
        emit SharesUpdated(_marketingShare, _cexShare, _operationsShare);
    }

    /**
     * @notice Returns key token constants for testing and UI
     * @return totalSupply The total token supply
     * @return initialBurn The initial burn amount
     * @return burnThreshold The burn threshold amount
     * @return maxTxAmount The maximum transaction amount
     */
    function getTokenConstants() external pure returns (
        uint256 totalSupply,
        uint256 initialBurn,
        uint256 burnThreshold,
        uint256 maxTxAmount
    ) {
        totalSupply = TOTAL_SUPPLY;
        initialBurn = INITIAL_BURN;
        burnThreshold = BURN_THRESHOLD;
        maxTxAmount = MAX_TX_AMOUNT;
    }

    /**
     * @notice Returns the current tax distribution percentages
     * @return burnShare Percentage of tax allocated to burn
     * @return marketingShare_ Percentage of tax allocated to marketing
     * @return liquidityShare_ Percentage of tax allocated to liquidity
     */
    function getTaxDistribution() external pure returns (
        uint256 burnShare,
        uint256 marketingShare_,
        uint256 liquidityShare_
    ) {
        burnShare = 60;
        marketingShare_ = 25;
        liquidityShare_ = 15;
    }

    /**
     * @notice Enable or disable automatic swap and liquify
     * @param enabled Whether automatic swaps should be enabled
     */
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        emit SwapEnabledUpdated(enabled);
    }

    /**
     * @notice Configure limits for DEX → DEX transfers
     * @param _maxAmount Maximum amount allowed (0 = no limit)
     */
    function setDexToDexLimit(uint256 _maxAmount) external onlyOwner {
        maxDexToDexAmount = _maxAmount;
    }

    /**
     * @notice Check DEX → DEX status for an address
     * @param account Address to check
     * @return canTransfer Whether can transfer now
     * @return timeLeft Time remaining before next transfer (in seconds)
     */
    function getDexToDexStatus(address account) external view returns (
        bool canTransfer,
        uint256 timeLeft
    ) {
        // FIXED: If no previous transfer, allow
        if (lastDexToDexTime[account] == 0) {
            canTransfer = true;
            timeLeft = 0;
            return (canTransfer, timeLeft);
        }
        
        uint256 nextAllowedTime = lastDexToDexTime[account] + DEX_TO_DEX_COOLDOWN;
        canTransfer = block.timestamp >= nextAllowedTime;
        timeLeft = canTransfer ? 0 : nextAllowedTime - block.timestamp;
    }

    /**
     * @notice Check if trading is enabled and get launch details
     * @return enabled True if trading is active
     * @return launchBlockNumber Block when trading was enabled  
     * @return blocksUntilUnrestricted Blocks remaining for anti-bot protection
     * @return isProtectionActive Whether anti-bot protection is currently active
     */
    function getTradingStatus() external view returns (
        bool enabled,
        uint256 launchBlockNumber,
        uint256 blocksUntilUnrestricted,
        bool isProtectionActive
    ) {
        enabled = tradingEnabled;
        launchBlockNumber = launchBlock;
        
        if (tradingEnabled && block.number <= launchBlock + ANTI_BOT_BLOCKS) {
            blocksUntilUnrestricted = (launchBlock + ANTI_BOT_BLOCKS) - block.number;
            isProtectionActive = true;
        } else {
            blocksUntilUnrestricted = 0;
            isProtectionActive = false;
        }
    }

    /**
     * @notice Check if an address would be blocked by anti-bot protection
     * @param account Address to check
     * @return blocked True if address would be blocked
     * @return reason Reason for blocking (if any)
     */
    function getAntiBotStatus(address account) external view returns (
        bool blocked,
        string memory reason
    ) {
        if (!tradingEnabled || block.number > launchBlock + ANTI_BOT_BLOCKS) {
            return (false, "Protection not active");
        }
        
        if (_isContract(account)) {
            return (true, "Contract blocked during launch");
        }
        
        return (false, "Address allowed");
    }

    /**
     * @dev Internal function to detect if address is a contract
     * @param account Address to check
     * @return bool True if address has code (is contract)
     */
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @notice Fallback function to receive BNB
     * @dev Required for receiving BNB from router swaps
     */
    receive() external payable {}

    /**
     * @notice Finalizes the contract by renouncing ownership and disabling trading
     * @dev This function can only be called after the trading has been enabled for 30 days
     * @dev Emits ContractFinalized and OwnershipRenounced events
     */
    function finalizeAndRenounce() external onlyOwner {
        require(tradingEnabled, "Trading must be enabled");
        require(block.timestamp > deploymentTime + 30 days, "Must wait 30 days");
        
        _transferOwnership(address(0));
        
        emit ContractFinalized(block.timestamp);
        emit OwnershipRenounced(block.timestamp);
    }
}

