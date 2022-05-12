// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering (engineering@moonstream.to)
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Adapted from the ERC20 platform token for the Moonstream DAO.
 */

pragma solidity ^0.8.0;

import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

import "./LibBank.sol";
import "./LibServerSideSigning.sol";
import "./diamond/libraries/LibDiamond.sol";


contract StashFacet {
    constructor() {}

    event Stashed(
        address indexed player,
        address indexed token,
        uint256 amount
    );

    event Unstashed(
        address indexed player,
        address indexed token,
        uint256 indexed requestId,
        uint256 amount
    );

    event StashedMultiple(
        address indexed player,
        address[] tokenAddresses,
        uint256[] tokenAmounts
    );

    event UnstashedMultiple(
        address indexed player,
        uint256 indexed requestId,
        address[] tokenAddresses,
        uint256[] tokenAmounts
    );

    function getUNIMAddress() external view returns (address) {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        return bs.UNIMAddress;
    }

    function getRBWAddress() external view returns (address) {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        return bs.RBWAddress;
    }

    function setGameServer(address newGameServer) external {
        LibDiamond.enforceIsContractOwner();
        LibBank.setGameServer(newGameServer);
    }

    function getGameServer() external view returns (address) {
        return LibBank.gameServer();
    }

    function stashUNIM(uint256 amount) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        LibBank._stashERC20Token(bs.UNIMAddress, msg.sender, amount);
        emit Stashed(msg.sender, bs.UNIMAddress, amount);
    }

    function unstashUNIMGenerateMessageHash(
        address player,
        uint256 amount,
        uint256 requestId,
        uint256 blockDeadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "UnstashUNIMPayload(address player, uint256 amount, uint256 requestId, uint256 blockDeadline)"
                ),
                player,
                amount,
                requestId,
                blockDeadline
            )
        );
        bytes32 digest = LibServerSideSigning._hashTypedDataV4(structHash);
        return digest;
    }

    function unstashUNIMWithSignature(
        uint256 amount,
        uint256 requestId,
        uint256 blockDeadline,
        bytes memory signature
    ) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();

        bytes32 hash = unstashUNIMGenerateMessageHash(
            msg.sender,
            amount,
            requestId,
            blockDeadline
        );
        address gameServer = LibBank.gameServer();
        require(
            SignatureChecker.isValidSignatureNow(gameServer, hash, signature),
            "StashFacet: unstashUNIMWithSignature -- Payload must be signed by game server"
        );
        require(
            !LibServerSideSigning._checkRequest(requestId),
            "StashFacet: unstashUNIMWithSignature -- Request has already been fulfilled"
        );
        require(
            block.number <= blockDeadline,
            "StashFacet: unstashUNIMWithSignature -- Block deadline has expired"
        );
        LibServerSideSigning._completeRequest(requestId);

        LibBank._unstashERC20Token(bs.UNIMAddress, msg.sender, amount);

        emit Unstashed(msg.sender, bs.UNIMAddress, requestId, amount);
    }

    function stashRBW(uint256 amount) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        LibBank._stashERC20Token(bs.RBWAddress, msg.sender, amount);
        emit Stashed(msg.sender, bs.RBWAddress, amount);
    }

    function unstashRBWGenerateMessageHash(
        address player,
        uint256 amount,
        uint256 requestId,
        uint256 blockDeadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "UnstashRBWPayload(address player, uint256 amount, uint256 requestId, uint256 blockDeadline)"
                ),
                player,
                amount,
                requestId,
                blockDeadline
            )
        );
        bytes32 digest = LibServerSideSigning._hashTypedDataV4(structHash);
        return digest;
    }

    function unstashRBWWithSignature(
        uint256 amount,
        uint256 requestId,
        uint256 blockDeadline,
        bytes memory signature
    ) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();

        bytes32 hash = unstashRBWGenerateMessageHash(
            msg.sender,
            amount,
            requestId,
            blockDeadline
        );
        address gameServer = LibBank.gameServer();
        require(
            SignatureChecker.isValidSignatureNow(gameServer, hash, signature),
            "StashFacet: unstashRBWWithSignature -- Payload must be signed by game server"
        );
        require(
            !LibServerSideSigning._checkRequest(requestId),
            "StashFacet: unstashRBWWithSignature -- Request has already been fulfilled"
        );
        require(
            block.number <= blockDeadline,
            "StashFacet: unstashRBWWithSignature -- Block deadline has expired"
        );
        LibServerSideSigning._completeRequest(requestId);

        LibBank._unstashERC20Token(bs.RBWAddress, msg.sender, amount);

        emit Unstashed(msg.sender, bs.RBWAddress, requestId, amount);
    }

    function stashUNIMAndRBW(uint256 amountUNIM, uint256 amountRBW) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();
        LibBank._stashERC20Token(bs.UNIMAddress, msg.sender, amountUNIM);
        LibBank._stashERC20Token(bs.RBWAddress, msg.sender, amountRBW);
        // emit Stashed(msg.sender, bs.UNIMAddress, amountUNIM);
        // emit Stashed(msg.sender, bs.RBWAddress, amountRBW);
        address[] memory tokenAddresses = new address[](2);
        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAddresses[0] = bs.UNIMAddress;
        tokenAddresses[1] = bs.RBWAddress;
        tokenAmounts[0] = amountUNIM;
        tokenAmounts[1] = amountRBW;
        emit StashedMultiple(msg.sender, tokenAddresses, tokenAmounts);
    }

    function unstashUNIMAndRBWGenerateMessageHash(
        address player,
        uint256 amountUNIM,
        uint256 amountRBW,
        uint256 requestId,
        uint256 blockDeadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "UnstashUNIMAndRBWPayload(address player, uint256 amountUNIM, uint256 amountRBW, uint256 requestId, uint256 blockDeadline)"
                ),
                player,
                amountUNIM,
                amountRBW,
                requestId,
                blockDeadline
            )
        );
        bytes32 digest = LibServerSideSigning._hashTypedDataV4(structHash);
        return digest;
    }

    function unstashUNIMAndRBWWithSignature(
        uint256 amountUNIM,
        uint256 amountRBW,
        uint256 requestId,
        uint256 blockDeadline,
        bytes memory signature
    ) external {
        LibBank.BankStorage storage bs = LibBank.bankStorage();

        bytes32 hash = unstashUNIMAndRBWGenerateMessageHash(
            msg.sender,
            amountUNIM,
            amountRBW,
            requestId,
            blockDeadline
        );
        address gameServer = LibBank.gameServer();
        require(
            SignatureChecker.isValidSignatureNow(gameServer, hash, signature),
            "StashFacet: unstashUNIMAndRBWWithSignature -- Payload must be signed by game server"
        );
        require(
            !LibServerSideSigning._checkRequest(requestId),
            "StashFacet: unstashUNIMAndRBWWithSignature -- Request has already been fulfilled"
        );
        require(
            block.number <= blockDeadline,
            "StashFacet: unstashUNIMAndRBWWithSignature -- Block deadline has expired"
        );
        LibServerSideSigning._completeRequest(requestId);

        LibBank._unstashERC20Token(bs.UNIMAddress, msg.sender, amountUNIM);
        LibBank._unstashERC20Token(bs.RBWAddress, msg.sender, amountRBW);

        address[] memory tokenAddresses = new address[](2);
        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAddresses[0] = bs.UNIMAddress;
        tokenAddresses[1] = bs.RBWAddress;
        tokenAmounts[0] = amountUNIM;
        tokenAmounts[1] = amountRBW;
        emit UnstashedMultiple(msg.sender, requestId, tokenAddresses, tokenAmounts);
    }
}
