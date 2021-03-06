/**
 * Copyright 2017–2018, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";

import "../proxy/BZxProxiable.sol";
import "../shared/OrderTakingFunctions.sol";


contract BZxOrderTakingOnChain2 is BZxStorage, BZxProxiable, OrderTakingFunctions {
    using SafeMath for uint256;

    constructor() public {}

    function()  
        public
    {
        revert("fallback not allowed");
    }

    function initialize(
        address _target)
        public
        onlyOwner
    {
        targets[bytes4(keccak256("preSign(address,address[6],uint256[10],bytes,bytes)"))] = _target;
        targets[bytes4(keccak256("preSignWithHash(address,bytes32,bytes)"))] = _target;
        targets[bytes4(keccak256("getLoanOrderHash(address[6],uint256[10],bytes)"))] = _target;
        targets[bytes4(keccak256("isValidSignature(address,bytes32,bytes)"))] = _target;
        targets[bytes4(keccak256("getInitialCollateralRequired(address,address,address,uint256,uint256)"))] = _target;
    }

    /// @dev Approves a hash on-chain using any valid signature type.
    ///      After presigning a hash, the preSign signature type will become valid for that hash and signer.
    /// @param signer Address that should have signed the hash generated by the loanOrder parameters given.
    /// @param orderAddresses Array of order's makerAddress, loanTokenAddress, interestTokenAddress, collateralTokenAddress, feeRecipientAddress, oracleAddress.
    /// @param orderValues Array of order's loanTokenAmount, interestAmount, initialMarginAmount, maintenanceMarginAmount, lenderRelayFee, traderRelayFee, maxDurationUnixTimestampSec, expirationUnixTimestampSec, makerRole (0=lender, 1=trader), and salt.
    /// @param oracleData An arbitrary length bytes stream to pass to the oracle.
    /// @param signature Proof that the hash has been signed by signer.
    function preSign(
        address signer,
        address[6] orderAddresses,
        uint[10] orderValues,
        bytes oracleData,
        bytes signature)
        external
        nonReentrant
    {
        _preSign(
            signer,
            _getLoanOrderHash(orderAddresses, orderValues, oracleData),
            signature
        );
    }

    /// @dev Approves a hash on-chain using any valid signature type.
    ///      After presigning a hash, the preSign signature type will become valid for that hash and signer.
    /// @param signer Address that should have signed the given hash.
    /// @param hash Signed Keccak-256 hash.
    /// @param signature Proof that the hash has been signed by signer.
    function preSignWithHash(
        address signer,
        bytes32 hash,
        bytes signature)
        external
        nonReentrant
    {
        _preSign(
            signer,
            hash,
            signature
        );
    }

    /// @dev Calculates Keccak-256 hash of order with specified parameters.
    /// @param orderAddresses Array of order's makerAddress, loanTokenAddress, interestTokenAddress, collateralTokenAddress, feeRecipientAddress, oracleAddress.
    /// @param orderValues Array of order's loanTokenAmount, interestAmount, initialMarginAmount, maintenanceMarginAmount, lenderRelayFee, traderRelayFee, maxDurationUnixTimestampSec, expirationUnixTimestampSec, makerRole (0=lender, 1=trader), and salt.
    /// @param oracleData An arbitrary length bytes stream to pass to the oracle.
    /// @return Keccak-256 hash of loanOrder.
    function getLoanOrderHash(
        address[6] orderAddresses,
        uint[10] orderValues,
        bytes oracleData)
        public
        view
        returns (bytes32)
    {
        return _getLoanOrderHash(orderAddresses, orderValues, oracleData);
    }

    /// @dev Verifies that an order signature is valid.
    /// @param signer address of signer.
    /// @param hash Signed Keccak-256 hash.
    /// @param signature ECDSA signature in raw bytes (rsv) + signatureType.
    /// @return Validity of order signature.
    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes signature)
        public
        view
        returns (bool)
    {
        return _isValidSignature(
            signer,
            hash,
            signature);
    }

    /// @dev Calculates the initial collateral required to open the loan.
    /// @param collateralTokenAddress The collateral token used by the trader.
    /// @param oracleAddress The oracle address specified in the loan order.
    /// @param loanTokenAmountFilled The amount of loan token borrowed.
    /// @param initialMarginAmount The initial margin percentage amount (i.e. 50 == 50%)
    /// @return The minimum collateral requirement to open the loan.
    function getInitialCollateralRequired(
        address loanTokenAddress,
        address collateralTokenAddress,
        address oracleAddress,
        uint loanTokenAmountFilled,
        uint initialMarginAmount)
        public
        view
        returns (uint collateralTokenAmount)
    {
        collateralTokenAmount = _getCollateralRequired(
            loanTokenAddress,
            collateralTokenAddress,
            oracleAddress,
            loanTokenAmountFilled,
            initialMarginAmount);
    }

    function _preSign(
        address signer,
        bytes32 hash,
        bytes signature)
        internal
    {
        if (signer != msg.sender) {
            require(
                _isValidSignature(
                    signer,
                    hash,
                    signature
                ),
                "INVALID_SIGNATURE"
            );
        }
        preSigned[hash][signer] = true;
    }
}

