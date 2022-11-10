// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {PluginUUPSUpgradeable} from '../lib/plugin/PluginUUPSUpgradeable.sol';
import {IDAO} from '../lib/interfaces/IDAO.sol';
import './ArrayUtils.sol';

contract Redemptions is PluginUUPSUpgradeable {
    using SafeERC20 for IERC20;
    using ArrayUtils for address[];

    /* ====================================================================== //
                                        PERMISSIONS
    // ====================================================================== */
    bytes32 public constant REDEEM_PERMISSION_ID = keccak256('REDEEM_PERMISSION_ID');
    bytes32 public constant MANAGE_TOKENS_PERMISSION_ID = keccak256('MANAGE_TOKENS_PERMISSION_ID');

    /* ====================================================================== //
                                        ERRORS
    // ====================================================================== */
    error REDEEMABLE_TOKEN_LIST_FULL();
    error DUPLICATE_REDEEMABLE_TOKEN();
    error INSUFFICIENT_BALANCE();
    error TOKEN_ALREADY_ADDED();
    error TOKEN_NOT_CONTRACT();
    error CANNOT_REDEEM_ZERO();
    error TOKEN_NOT_ADDED();

    /* ====================================================================== //
                                        EVENTS
    // ====================================================================== */

    event AddRedeemableToken(address indexed token);
    event RemoveRedeemableToken(address indexed token);
    event Redeem(address indexed redeemer, uint256 amount);

    /* ====================================================================== //
                                        STORAGE
    // ====================================================================== */

    /// @notice The token that is used to redeem for other tokens
    IERC20 public redemptionToken;

    /// @notice The list of redeemable tokens
    address[] internal redeemableTokens;

    /// @notice Is the token redeemable
    mapping(address => bool) public redeemableTokenAdded;

    /// @notice The maximum number of redeemable tokens
    uint256 public constant REDEEMABLE_TOKENS_MAX_SIZE = 30;

    /// @notice ID assigned to IDAO.Action calls
    uint256 callId;

    /// @notice Initializes the plugin.
    /// @param _dao The contract of the associated DAO.
    /// @param _redeemableTokens The list of redeemable tokens.
    function initialize(
        IDAO _dao,
        IERC20 _redemptionToken,
        address[] memory _redeemableTokens
    ) external initializer {
        __PluginUUPSUpgradeable_init(_dao);

        if (_redeemableTokens.length >= REDEEMABLE_TOKENS_MAX_SIZE)
            revert REDEEMABLE_TOKEN_LIST_FULL();

        for (uint256 i = 0; i < _redeemableTokens.length; i++) {
            address token = _redeemableTokens[i];
            if (redeemableTokenAdded[token] == true) revert DUPLICATE_REDEEMABLE_TOKEN();
            if (!isContract(token)) revert TOKEN_NOT_CONTRACT();

            redeemableTokenAdded[token] = true;
        }
        redemptionToken = _redemptionToken;
        callId = 0;
    }

    /* ====================================================================== //
                                PERMISSIONED FUNCTIONS
    // ====================================================================== */

    /// @notice Adds a new redeemable token.
    /// @param _token The address of the token to add.
    function addRedeemableToken(address _token) external auth(MANAGE_TOKENS_PERMISSION_ID) {
        if (!isContract(_token)) revert TOKEN_NOT_CONTRACT();
        if (redeemableTokenAdded[_token]) revert TOKEN_ALREADY_ADDED();
        if (redeemableTokens.length > REDEEMABLE_TOKENS_MAX_SIZE)
            revert REDEEMABLE_TOKEN_LIST_FULL();

        redeemableTokenAdded[_token] = true;
        redeemableTokens.push(_token);

        // approve token
        // max uint256
        approveTokenFromDAO(_token, type(uint256).max);

        emit AddRedeemableToken(_token);
    }

    /// @notice Removes a redeemable token.
    /// @param _token The address of the token to remove.
    function removeRedeemableToken(address _token) external auth(MANAGE_TOKENS_PERMISSION_ID) {
        if (!redeemableTokenAdded[_token]) revert TOKEN_NOT_ADDED();

        redeemableTokenAdded[_token] = false;
        redeemableTokens.deleteItem(_token);

        approveTokenFromDAO(_token, 0);

        emit RemoveRedeemableToken(_token);
    }

    /* ====================================================================== //
                                    USER FUNCTIONS
    // ====================================================================== */

    /// @notice Redeems tokens for the underlying redemption token.
    /// @param _redeemableAmount The amount of tokens to redeem.
    function redeem(uint256 _redeemableAmount) external auth(MANAGE_TOKENS_PERMISSION_ID) {
        if (_redeemableAmount == 0) revert CANNOT_REDEEM_ZERO();
        if (redemptionToken.allowance(_msgSender(), address(this)) < _redeemableAmount)
            revert INSUFFICIENT_BALANCE();

        uint256 redemptionAmount;
        uint256 totalRedemptionAmount;
        uint256 daoTokenBalance;
        uint256 totalSupply = redemptionToken.totalSupply();

        redemptionToken.safeTransferFrom(_msgSender(), address(dao), _redeemableAmount);

        for (uint256 i = 0; i < redeemableTokens.length; i++) {
            daoTokenBalance = IERC20(redeemableTokens[i]).balanceOf(address(dao));

            redemptionAmount = (_redeemableAmount * daoTokenBalance) / (totalSupply);
            totalRedemptionAmount = totalRedemptionAmount + redemptionAmount;

            if (redemptionAmount > 0) {
                IERC20(redeemableTokens[i]).safeTransferFrom(
                    address(dao),
                    _msgSender(),
                    redemptionAmount
                );
            }
        }

        emit Redeem(_msgSender(), _redeemableAmount);
    }

    /// @notice Returns the list of redeemable tokens.
    function getRedeemableTokens() external view returns (address[] memory) {
        return redeemableTokens;
    }

    /* ====================================================================== //
                                    INTERNAL FUNCTIONS
    // ====================================================================== */

    /// @notice Approves the Redemption Plugin to spend the token from the DAO.
    /// @param _token The address of the token to approve.
    /// @param _amount The amount to approve.
    function approveTokenFromDAO(address _token, uint256 _amount) internal {
        IDAO.Action[] memory actions = new IDAO.Action[](1);
        actions[0] = IDAO.Action({
            to: _token,
            value: 0,
            data: abi.encodeWithSelector(
                bytes4(keccak256('approve(address,uint256)')),
                address(this),
                _amount
            )
        });
        dao.execute(callId++, actions);
    }

    /// @notice Checks if the address is a contract.
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[48] private __gap;
}
