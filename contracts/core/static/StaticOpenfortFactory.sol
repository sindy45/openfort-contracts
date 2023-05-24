// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
// Smart wallet implementation to use
import {StaticOpenfortAccount} from "./StaticOpenfortAccount.sol";
// Interfaces
import {IBaseOpenfortFactory} from "../../interfaces/IBaseOpenfortFactory.sol";

/**
 * @title StaticOpenfortFactory (Non-upgradeable)
 * @author Eloi<eloi@openfort.xyz>
 * @notice Contract to create account factories
 * It inherits from:
 *  - IBaseOpenfortFactory
 */
contract StaticOpenfortFactory is IBaseOpenfortFactory {
    address public immutable entrypointContract;
    address public immutable accountImplementation;

    constructor(address _entrypoint) {
        require(_entrypoint != address(0), "_entrypoint cannot be 0");
        entrypointContract = _entrypoint;
        accountImplementation = address(new StaticOpenfortAccount());
    }

    /*
     * @notice Deploy a new Account for _admin.
     */
    function createAccount(address _admin, bytes calldata _data) external returns (address account) {
        address impl = accountImplementation;
        bytes32 salt = keccak256(abi.encode(_admin));
        account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        _initializeAccount(account, _admin, entrypointContract, _data);

        emit AccountCreated(account, _admin);
    }

    /*
     * @notice Deploy a new Account for _admin and a given nonce.
     */
    function createAccountWithNonce(address _admin, bytes calldata _data, uint256 nonce)
        external
        returns (address account)
    {
        address impl = accountImplementation;
        bytes32 salt = keccak256(abi.encode(_admin, nonce));
        account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        _initializeAccount(account, _admin, entrypointContract, _data);

        emit AccountCreated(account, _admin);
    }

    /*
     * @notice Return the address of an Account that would be deployed with the given admin signer.
     */
    function getAddress(address _adminSigner) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(_adminSigner));
        return Clones.predictDeterministicAddress(accountImplementation, salt);
    }

    /*
     * @notice Return the address of an Account that would be deployed with the given admin signer and nonce.
     */
    function getAddressWithNonce(address _adminSigner, uint256 nonce) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(_adminSigner, nonce));
        return Clones.predictDeterministicAddress(accountImplementation, salt);
    }

    /*
     * @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
     */
    function _initializeAccount(address _account, address _admin, address _entrypointContract, bytes calldata _data)
        internal
    {
        StaticOpenfortAccount(payable(_account)).initialize(_admin, _entrypointContract, _data);
    }
}
