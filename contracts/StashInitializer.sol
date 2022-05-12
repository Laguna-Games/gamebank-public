// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering (engineering@moonstream.to)
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Adapted from Initializer for Terminus contract.
 */

pragma solidity ^0.8.9;

import "./LibBank.sol";
import "./LibServerSideSigning.sol";

contract StashInitializer {
    // These variables are just set on the deployed initializer as recommendations (for convenience).
    // A caller using this initializer with a Diamond contract can pass different arguments with the
    // intialization calldata if they wish.
    // They have no effect on DELEGATECALL operations.
    address UNIMAddress;
    address RBWAddress;

    constructor(address _UNIMAddress, address _RBWAddress) {
        UNIMAddress = _UNIMAddress;
        RBWAddress = _RBWAddress;
    }

    function init(address _UNIMAddress, address _RBWAddress) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        bs.UNIMAddress = _UNIMAddress;
        bs.RBWAddress = _RBWAddress;

        // Set up server side signing parameters for EIP712
        LibServerSideSigning._setEIP712Parameters("Crypto Unicorns Game Bank", "0.0.1");
    }

    function initializerUNIMAddress() external view returns (address) {
        return UNIMAddress;
    }

    function initializerRBWAddress() external view returns (address) {
        return RBWAddress;
    }
}
