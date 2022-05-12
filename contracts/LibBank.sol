// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./diamond/libraries/LibDiamond.sol";

library LibBank {
    bytes32 constant BANK_STORAGE_POSITION =
        keccak256("CryptoUnicorns.GameBank.storage");

    struct BankStorage {
        address gameServer;
        address UNIMAddress;
        address RBWAddress;
    }

    function bankStorage() internal pure returns (BankStorage storage bs) {
        bytes32 position = BANK_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

    function setGameServer(address newGameServer) internal {
        // We double-enforce contract ownership here because
        // this functionality needs to be highly protected.
        LibDiamond.enforceIsContractOwner();
        BankStorage storage bs = bankStorage();
        bs.gameServer = newGameServer;
    }

    function gameServer() internal view returns (address) {
        return bankStorage().gameServer;
    }

    function _stashERC20Token(
        address tokenAddress,
        address stasher,
        uint256 amount
    ) internal {
        address bankAddress = address(this);
        IERC20 token = IERC20(tokenAddress);
        require(
            token.allowance(stasher, bankAddress) >= amount,
            "LibBank: _stashERC20Token -- Insufficient token allowance for Game Bank"
        );
        token.transferFrom(stasher, bankAddress, amount);
    }

    function _unstashERC20Token(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) internal {
        address bankAddress = address(this);
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(bankAddress) >= amount,
            "LibBank: _unstashERC20Token -- Insufficient amount of tokens in reserve"
        );
        token.transfer(recipient, amount);
    }
}
