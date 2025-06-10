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
 * @author Vaulton Team
 * @notice A deflationary token that automatically removes taxes once 75% of supply is burned
 * @dev Implements automatic burn mechanism and strategic liquidity management
 * 
 * SECURITY: Wallets are set once at deployment and CANNOT be changed (no updateWallets function)
 * 
 * Key Features:
 * - 60% of taxes are burned automatically on each transaction
 * - 40% of taxes accumulate for marketing (manually convertible to BNB)
 * - Taxes automatically removed when 75% of total supply is burned
 * - No instant liquidity mechanism - clean tax distribution
 * - Owner can renounce after conditions are met (PinkSale compatible)
 * - Fund wallets are IMMUTABLE - maximum rug pull protection
 * - LP tokens burned for permanent liquidity (superior to time locks)
 */
contract Vaulton is ERC20, Ownable, ReentrancyGuard {
    // ========================================
    // CONSTANTS
    // ========================================
    
    /// @notice Total supply of VAULTON tokens (50 million)
    uint256 public constant TOTAL_SUPPLY = 50_000_000 * 10**18;
    
    /// @notice Amount of tokens burned at deployment (15 million)
    uint256 public constant INITIAL_BURN = 15_000_000 * 10**18;
    
    /// @notice Threshold at which taxes are permanently removed (75% of total supply)
    uint256 public constant BURN_THRESHOLD = (TOTAL_SUPPLY * 75) / 100;

    /// @dev Tax distribution percentages
    uint256 private constant BURN_PERCENT = 60;     // 60% of taxes burned
    uint256 private constant MARKETING_PERCENT = 40; // 40% for marketing

    /// @dev Tax rates (immutable)
    uint8 private constant BUY_TAX = 5;              // 5% buy tax
    uint8 private constant SELL_TAX = 10;            // 10% sell tax
    uint8 private constant WALLET_TAX = 3;           // 3% wallet-to-wallet tax
    
    /// @dev Anti-bot protection duration in blocks
    uint256 private constant ANTI_BOT_BLOCKS = 3;

    /// @notice BNB distribution shares for fund distribution
    uint256 public constant MARKETING_SHARE = 45;    // 45% to marketing wallet
    uint256 public constant CEX_SHARE = 25;          // 25% to CEX wallet
    uint256 public constant OPERATIONS_SHARE = 30;   // 30% to operations wallet

    // ========================================
    // STATE VARIABLES
    // ========================================

    /// @notice Total amount of tokens burned throughout contract lifetime
    uint256 public burnedTokens;
    
    /// @notice Marketing tokens accumulated from taxes (convertible to BNB)
    uint256 public marketingTokensAccumulated;

    /// @notice Immutable reference to PancakeSwap router
    IUniswapV2Router02 public immutable pancakeRouter;
    
    /// @notice Address of the main trading pair (VAULTON/WBNB)
    address public pancakePair;

    /// @notice Wallet addresses for fund distribution (SET ONCE - cannot be changed)
    address public marketingWallet;   // Immutable after deployment
    address public cexWallet;         // Immutable after deployment  
    address public operationsWallet;  // Immutable after deployment

    /// @notice Trading state and configuration
    bool public tradingEnabled;
    bool public taxesRemoved;
    uint32 public launchBlock;

    /// @notice Mapping to identify DEX pairs for tax calculation
    mapping(address => bool) public isDexPair;
    
    /// @dev Mapping to track fee exclusions
    mapping(address => bool) private isExcludedFromFees;

    /// @dev Lock to prevent reentrancy during swaps
    bool private inSwapAndLiquify;

    // ========================================
    // EVENTS
    // ========================================

    /// @notice Emitted when taxes are applied to a transaction
    event TaxApplied(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, string taxType);
    
    /// @notice Emitted when taxes are permanently removed at 75% burn
    event TaxesRemoved();
    
    /// @notice Emitted when burn progress is updated
    event BurnProgressUpdated(uint256 burnedAmount, uint256 burnPercentage);
    
    /// @notice Emitted when trading is enabled
    event TradingEnabled(uint256 blockNumber);
    
    /// @notice Emitted when BNB is distributed to wallets
    event FundsDistributed(uint256 marketingAmount, uint256 cexAmount, uint256 operationsAmount);
    
    /// @notice Emitted when marketing tokens are converted to BNB
    event MarketingTokensProcessed(uint256 tokensSwapped, uint256 bnbReceived);
    
    /// @notice Emitted when a trading pair is automatically detected
    event PairAutoDetected(address indexed pair);

    // ========================================
    // MODIFIERS
    // ========================================

    /// @dev Prevents reentrancy during swap operations
    modifier lockTheSwap() {
        require(!inSwapAndLiquify, "Swap locked");
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /// @dev Provides anti-bot protection during first 3 blocks after launch
    modifier antiBotProtection() {
        if (tradingEnabled && block.number <= launchBlock + ANTI_BOT_BLOCKS) {
            if (_isContract(msg.sender)) {
                require(_isAllowedContract(msg.sender), "Contract not allowed during launch");
            }
        }
        _;
    }

    // ========================================
    // CONSTRUCTOR
    // ========================================

    /**
     * @notice Deploys the Vaulton token contract with PERMANENT wallet addresses
     * @param _pancakeRouter Address of the PancakeSwap V2 router
     * @param _marketingWallet Address of the marketing wallet (CANNOT be changed later)
     * @param _cexWallet Address of the CEX wallet (CANNOT be changed later)
     * @param _operationsWallet Address of the operations wallet (CANNOT be changed later)
     * 
     * @dev Deployment Process:
     * 1. Mints 50M total supply to owner
     * 2. Burns 15M tokens immediately (30% initial burn)
     * 3. Sets IMMUTABLE wallet addresses (no update function exists)
     * 4. Excludes owner and contract from fees
     * 5. Initializes burn tracking and progress events
     * 
     * @dev Security Features:
     * - All wallet addresses are immutable post-deployment
     * - No admin functions to change core parameters
     * - Initial burn creates immediate deflationary pressure
     */
    constructor(
        address _pancakeRouter,
        address _marketingWallet,
        address _cexWallet, 
        address _operationsWallet
    ) ERC20("Vaulton", "VAULTON") {
        require(_pancakeRouter != address(0), "Invalid router address");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_cexWallet != address(0), "Invalid CEX wallet");
        require(_operationsWallet != address(0), "Invalid operations wallet");
        
        pancakeRouter = IUniswapV2Router02(_pancakeRouter);
        
        // Set IMMUTABLE wallet addresses
        marketingWallet = _marketingWallet;
        cexWallet = _cexWallet;
        operationsWallet = _operationsWallet;

        // Mint total supply and perform initial burn
        _mint(owner(), TOTAL_SUPPLY);
        _burn(owner(), INITIAL_BURN);
        burnedTokens = INITIAL_BURN;
        
        emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);

        // Exclude system addresses from fees
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
    }

    // ========================================
    // CORE TRANSFER LOGIC
    // ========================================

    /**
     * @dev Hook called before token transfers to setup pairs and check burn threshold
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Auto-detect and setup trading pairs
        _detectAndSetupPair();

        // Check if burn threshold reached and remove taxes
        if (burnedTokens >= BURN_THRESHOLD && !taxesRemoved) {
            _removeTaxes();
        }
    }

    /**
     * @dev Core transfer function with tax logic and anti-bot protection
     */
    function _transfer(address from, address to, uint256 amount) internal override antiBotProtection {
        require(from != address(0) && to != address(0), "Zero address");
        require(amount > 0, "Zero amount");
        
        if (!tradingEnabled) {
            require(
                from == owner() || 
                to == owner() || 
                from == address(this) || 
                to == address(this), 
                "Trading not enabled"
            );
        }
        
        uint256 taxAmount = _calculateTax(from, to, amount);
        
        if (taxAmount > 0) {
            super._transfer(from, to, amount - taxAmount);
            super._transfer(from, address(this), taxAmount);
            _processTaxes(taxAmount);
            emit TaxApplied(from, to, amount, taxAmount, _getTaxType(from, to));
        } else {
            super._transfer(from, to, amount);
        }
    }

    // ========================================
    // TAX PROCESSING
    // ========================================

    /**
     * @dev Calculates tax amount based on transaction type
     * @param from Sender address
     * @param to Recipient address  
     * @param amount Transaction amount
     * @return Tax amount to be collected
     */
    function _calculateTax(address from, address to, uint256 amount) private view returns (uint256) {
        if (taxesRemoved || isExcludedFromFees[from] || isExcludedFromFees[to]) {
            return 0;
        }
        
        bool isBuy = isDexPair[from] && !isDexPair[to];
        bool isSell = !isDexPair[from] && isDexPair[to];
        bool isWalletToWallet = !isDexPair[from] && !isDexPair[to];
        
        uint256 taxRate;
        if (isBuy) {
            taxRate = BUY_TAX;          // 5%
        } else if (isSell) {
            taxRate = SELL_TAX;         // 10%
        } else if (isWalletToWallet) {
            taxRate = WALLET_TAX;       // 3%
        } else {
            taxRate = 0;
        }
        
        return (amount * taxRate) / 100;
    }

    /**
     * @dev Processes collected taxes with 60/40 split (burn/marketing)
     * @param taxAmount Total tax amount to process
     * 
     * Tax Distribution:
     * - 60% burned immediately to dead address
     * - 40% accumulated as marketing tokens (convertible to BNB)
     */
    function _processTaxes(uint256 taxAmount) private {
        uint256 burnAmount = (taxAmount * BURN_PERCENT) / 100;      // 60%
        uint256 marketingAmount = taxAmount - burnAmount;           // 40%
        
        if (burnAmount > 0) {
            super._transfer(address(this), address(0x000000000000000000000000000000000000dEaD), burnAmount);
            burnedTokens += burnAmount;
            emit BurnProgressUpdated(burnedTokens, (burnedTokens * 100) / TOTAL_SUPPLY);
        }
        
        if (marketingAmount > 0) {
            marketingTokensAccumulated += marketingAmount;
        }
    }

    /**
     * @dev Returns transaction type for event logging
     */
    function _getTaxType(address from, address to) private view returns (string memory) {
        if (isDexPair[from] && !isDexPair[to]) {
            return "buy";
        } else if (!isDexPair[from] && isDexPair[to]) {
            return "sell";
        } else {
            return "transfer";
        }
    }

    /**
     * @dev Permanently removes taxes when burn threshold is reached
     */
    function _removeTaxes() internal {
        require(!taxesRemoved, "Taxes already removed");
        taxesRemoved = true;
        emit TaxesRemoved();
    }

    // ========================================
    // LIQUIDITY FUNCTIONS
    // ========================================

    /**
     * @notice Adds liquidity to existing pair (PinkSale compatible)
     * @param tokenAmount Amount of tokens to add to liquidity
     * @dev Only works if pair already exists (safe for PinkSale)
     */
    function addLiquidity(uint256 tokenAmount) external payable onlyOwner {
        require(msg.value > 0, "Must send BNB");
        require(balanceOf(owner()) >= tokenAmount, "Insufficient owner tokens");
        
        address factory = pancakeRouter.factory();
        address existingPair = IUniswapV2Factory(factory).getPair(address(this), pancakeRouter.WETH());
        require(existingPair != address(0), "Pair must exist - use PinkSale to create first");
        
        _transfer(owner(), address(this), tokenAmount);
        _approve(address(this), address(pancakeRouter), tokenAmount);
        
        pancakeRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            tokenAmount * 95 / 100,
            msg.value * 95 / 100,
            address(0),
            block.timestamp + 300
        );
    }

    /**
     * @dev Swaps tokens for BNB using the router
     * @param tokenAmount Amount of tokens to swap
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(balanceOf(address(this)) >= tokenAmount, "Insufficient contract balance");
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        try pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300 // 5 minutes deadline
        ) {
            // Swap réussi - pas d'action nécessaire
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Swap failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            if (lowLevelData.length == 0) {
                revert("Swap failed: Unknown error");
            } else {
                revert("Swap failed: Low-level error");
            }
        }
    }

    /**
     * @dev Automatically detects and sets up the main trading pair
     */
    function _detectAndSetupPair() internal {
        address factory = pancakeRouter.factory();
        address pair = IUniswapV2Factory(factory).getPair(address(this), pancakeRouter.WETH());
        
        if (pair != address(0) && pancakePair == address(0)) {
            pancakePair = pair;
            isDexPair[pair] = true;
            emit PairAutoDetected(pair);
        }
        
        if (pancakePair != address(0) && !isDexPair[pancakePair]) {
            isDexPair[pancakePair] = true;
        }
    }

    // ========================================
    // ADMIN FUNCTIONS
    // ========================================

    /**
     * @notice Enables trading for the token
     * @dev Can only be called once by owner. Liquidity can be added before or after.
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
    
        tradingEnabled = true;
        launchBlock = uint32(block.number);
        emit TradingEnabled(block.number);
    }

    /**
     * @notice Excludes or includes an address from fees
     * @param _address Address to modify fee status for
     * @param _status True to exclude from fees, false to include
     */
    function excludeFromFees(address _address, bool _status) external onlyOwner {
        isExcludedFromFees[_address] = _status;
    }

    /**
     * @notice Sets DEX pair status for an address
     * @param _pair Address of the pair contract
     * @param _status True if this is a DEX pair, false otherwise
     */
    function setDexPair(address _pair, bool _status) external onlyOwner {
        isDexPair[_pair] = _status;
    }

    /**
     * @notice Converts a specific amount of accumulated marketing tokens to BNB
     * @param tokenAmount Amount of marketing tokens to convert
     * @dev Converts tokens via DEX swap and stores BNB in contract for distribution
     * @dev Use distributeFunds() after conversion to send BNB to wallets
     * 
     * Process:
     * 1. Validates sufficient marketing tokens available
     * 2. Swaps tokens for BNB via PancakeSwap
     * 3. Stores BNB in contract for later distribution
     * 4. Reduces marketingTokensAccumulated by converted amount
     */
    function convertMarketingTokens(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Amount must be greater than 0");
        require(tokenAmount <= marketingTokensAccumulated, "Insufficient marketing tokens");
        
        uint256 initialBnb = address(this).balance;
        swapTokensForBNB(tokenAmount);
        uint256 bnbReceived = address(this).balance - initialBnb;
        
        marketingTokensAccumulated -= tokenAmount;
        
        emit MarketingTokensProcessed(tokenAmount, bnbReceived);
    }

    /**
     * @notice Converts all accumulated marketing tokens to BNB
     * @dev Convenience function to convert entire marketing token balance
     * @dev Equivalent to calling convertMarketingTokens() with full balance
     */
    function convertAllMarketingTokens() external onlyOwner {
        require(marketingTokensAccumulated > 0, "No marketing tokens to convert");
        
        uint256 tokenAmount = marketingTokensAccumulated;
        uint256 initialBnb = address(this).balance;
        swapTokensForBNB(tokenAmount);
        uint256 bnbReceived = address(this).balance - initialBnb;
        
        marketingTokensAccumulated = 0;
        
        emit MarketingTokensProcessed(tokenAmount, bnbReceived);
    }

    /**
     * @notice Distributes contract BNB balance to IMMUTABLE designated wallets
     * @dev Distributes according to fixed percentages: 45% marketing, 25% CEX, 30% operations
     * @dev Wallets CANNOT be changed - provides maximum security against fund redirection
     * 
     * Distribution Breakdown:
     * - 45% to marketing wallet (campaigns, partnerships, development)
     * - 25% to CEX wallet (exchange listings, market making)
     * - 30% to operations wallet (team, infrastructure, legal)
     * 
     * Security Features:
     * - Wallet addresses are immutable (set once at deployment)
     * - No updateWallets() function exists
     * - ReentrancyGuard protection
     * - All transfers verified with require statements
     */
    function distributeFunds() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 totalBalance = address(this).balance;
        
        uint256 marketingAmount = (totalBalance * MARKETING_SHARE) / 100;   // 45%
        uint256 cexAmount = (totalBalance * CEX_SHARE) / 100;               // 25%
        uint256 operationsAmount = (totalBalance * OPERATIONS_SHARE) / 100; // 30%
        
        (bool success1, ) = marketingWallet.call{value: marketingAmount}("");
        require(success1, "Marketing transfer failed");
        
        (bool success2, ) = cexWallet.call{value: cexAmount}("");
        require(success2, "CEX transfer failed");
        
        (bool success3, ) = operationsWallet.call{value: operationsAmount}("");
        require(success3, "Operations transfer failed");
        
        emit FundsDistributed(marketingAmount, cexAmount, operationsAmount);
    }

    /**
     * @notice Renounces ownership of the contract (PinkSale compatible)
     * @dev Simple renouncement function. Use getRenounceStatus() to check if safe to renounce
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    // ========================================
    // VIEW FUNCTIONS
    // ========================================

    /**
     * @notice Returns comprehensive stats for dashboard display
     * @return burned Total tokens burned since deployment
     * @return burnProgress Progress towards 75% burn threshold (percentage)
     * @return marketingTokens Marketing tokens available for conversion to BNB
     * @return contractBnb BNB balance in contract ready for distribution
     * @return trading Whether trading is currently enabled
     * @return pair Address of main trading pair (VAULTON/WBNB)
     * @return taxesRemoved_ Whether taxes have been permanently removed
     * @return circulatingSupply Current circulating supply (total - burned)
     */
    function getQuickStats() external view returns (
        uint256 burned,
        uint256 burnProgress,
        uint256 marketingTokens,
        uint256 contractBnb,
        bool trading,
        address pair,
        bool taxesRemoved_,
        uint256 circulatingSupply
    ) {
        burned = burnedTokens;
        burnProgress = (burnedTokens * 100) / BURN_THRESHOLD;
        marketingTokens = marketingTokensAccumulated;
        contractBnb = address(this).balance;
        trading = tradingEnabled;
        pair = pancakePair;
        taxesRemoved_ = taxesRemoved;
        circulatingSupply = TOTAL_SUPPLY - burnedTokens;
    }

    /**
     * @notice Returns basic token information
     * @return name Token name
     * @return symbol Token symbol
     * @return totalSupply Initial total supply
     * @return circulatingSupply Current circulating supply (total - burned)
     * @return decimals Token decimals
     * @return burned Total burned tokens
     * @return burnPercentage Percentage of total supply burned
     */
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 circulatingSupply,
        uint8 decimals,
        uint256 burned,
        uint256 burnPercentage
    ) {
        name = "Vaulton";
        symbol = "VAULTON";
        totalSupply = TOTAL_SUPPLY;
        circulatingSupply = TOTAL_SUPPLY - burnedTokens;
        decimals = 18;
        burned = burnedTokens;
        burnPercentage = (burnedTokens * 100) / TOTAL_SUPPLY;
    }

    /**
     * @notice Returns current tax rates
     * @return buy Buy tax percentage
     * @return sell Sell tax percentage  
     * @return walletToWallet Wallet-to-wallet transfer tax percentage
     */
    function getTaxRates() external pure returns (uint8 buy, uint8 sell, uint8 walletToWallet) {
        return (BUY_TAX, SELL_TAX, WALLET_TAX);
    }

    /**
     * @notice Returns burn mechanism progress
     * @return currentBurned Total tokens burned so far
     * @return burnThreshold Threshold for tax removal (75% of total supply)
     * @return progressPercentage Progress towards threshold (percentage)
     * @return thresholdReached Whether the threshold has been reached
     */
    function getBurnProgress() external view returns (
        uint256 currentBurned,
        uint256 burnThreshold,
        uint256 progressPercentage,
        bool thresholdReached
    ) {
        uint256 progress = (burnedTokens * 100) / BURN_THRESHOLD;
        
        return (burnedTokens, BURN_THRESHOLD, progress, burnedTokens >= BURN_THRESHOLD);
    }

    // ========================================
    // INTERNAL HELPERS
    // ========================================

    /**
     * @dev Checks if an address is a contract
     * @param account Address to check
     * @return True if the address is a contract
     */
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @dev Checks if a contract address is allowed during anti-bot protection
     * @param account Contract address to check
     * @return True if the contract is allowed to trade during launch
     */
    function _isAllowedContract(address account) private view returns (bool) {
        if (account == address(pancakeRouter)) return true;
        if (pancakePair != address(0) && account == pancakePair) return true;
        if (isExcludedFromFees[account]) return true;
        if (isDexPair[account]) return true;
        
        return false;
    }

    /**
     * @dev Allows contract to receive BNB from swaps and liquidity operations
     */
    receive() external payable {
        // Contract can now receive BNB from PancakeSwap swaps
    }
}

