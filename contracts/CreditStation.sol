// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   CreditStation.sol - credit-station
 *   Copyright (C) 2025-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   credit-station is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   credit-station is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with credit-station.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.30;

// cspell:words IERC20

import {
    AccessManaged
} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import { AddressIsNotSet } from "./interfaces/error.sol";
import { ICreditStation, IERC20 } from "./interfaces/ICreditStation.sol";
import { IVersioned } from "./interfaces/IVersioned.sol";
import { PaymentId, SchainHash } from "./interfaces/types.sol";


/// @title Credit Station
/// @author Dmytro Stebaiev
/// @notice This contract is responsible for receiving payments for credits.
contract CreditStation is AccessManaged, IVersioned, ICreditStation {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice The version of the contract
    string public override version;
    /// @notice Address that receives the payments for credits
    address public receiver;
    PaymentId private _nextPaymentId = PaymentId.wrap(1);
    EnumerableMap.AddressToUintMap private _prices;

    /// @notice Emitted when a payment is received
    /// @param id The payment ID
    /// @param schainHash The hash of the target schain name
    /// @param from The address of the payer
    /// @param to The address of the credits receiver
    /// @param tokenAddress The address of the token used for payment
    event PaymentReceived(
        PaymentId indexed id,
        SchainHash indexed schainHash,
        address indexed from,
        address to,
        IERC20 tokenAddress
    );

    /// @notice Emitted when a token is allowed for payment
    /// @param token The address of the allowed token
    event TokenAllowed(IERC20 indexed token);
    /// @notice Emitted when a token is disallowed for payment
    /// @param token The address of the disallowed token
    event TokenDisallowed(IERC20 indexed token);
    /// @notice Emitted when the price is updated
    /// @param token The address of the token used for payment
    /// @param newPrice The new price of the credits batch in the specified token
    event PriceIsUpdated(IERC20 indexed token, uint256 newPrice);

    /// @notice Emitted when the receiver address is changed
    /// @param oldReceiver The old receiver address
    /// @param newReceiver The new receiver address
    event ReceiverWasChanged(address indexed oldReceiver, address indexed newReceiver);

    error TokenIsNotAccepted(IERC20 token);
    error TokenTransferFailed(IERC20 token, address from, uint256 amount);

    /// @notice Constructor
    /// @param accessManagerAddress The address of the Access Manager contract
    /// @param initialReceiver The initial receiver of the payments
    constructor(address accessManagerAddress, address initialReceiver) AccessManaged(accessManagerAddress) {
        require(initialReceiver != address(0), AddressIsNotSet());
        receiver = initialReceiver;
    }

    // External

    /// @notice Pay to get credits on an schain
    /// @param schainName The name of the schain
    /// @param purchaser The address purchased credits will be sent to
    /// @param token The address of the token to pay with
    function buy(
        string calldata schainName,
        address purchaser,
        IERC20 token
    )
        external
        override
    {
        (bool accepted, uint256 price) = _prices.tryGet(address(token));
        require(accepted, TokenIsNotAccepted(token));
        PaymentId currentPaymentId = _nextPaymentId;
        _nextPaymentId = _next(_nextPaymentId);

        emit PaymentReceived({
            id: currentPaymentId,
            schainHash: toSchainHash(schainName),
            from: msg.sender,
            to: purchaser,
            tokenAddress: token
        });

        require(token.transferFrom(msg.sender, receiver, price), TokenTransferFailed(token, msg.sender, price));
    }

    /// @notice Sets price of credits batch in a specific token
    /// @notice Setting price to 0 removes the token from accepted tokens list
    /// @param token The address of the token
    /// @param price The price of the credits batch in the specified token
    function setPrice(IERC20 token, uint256 price) external override restricted {
        if (price == 0) {
            require(_prices.remove(address(token)), TokenIsNotAccepted(token));
            emit TokenDisallowed(token);
        } else {
            if(_prices.set(address(token), price)) {
                emit TokenAllowed(token);
            } else {
                emit PriceIsUpdated(token, price);
            }
        }
    }

    /// @notice Sets the receiver address
    /// @param newReceiver The new receiver address
    function setReceiver(address newReceiver) external override restricted {
        require(newReceiver != address(0), AddressIsNotSet());
        emit ReceiverWasChanged(receiver, newReceiver);
        receiver = newReceiver;
    }

    /// @notice Sets the version of the contract
    /// @param newVersion The new version string
    function setVersion(string calldata newVersion) external override restricted {
        emit VersionChanged(version, newVersion);
        version = newVersion;
    }

    // External view

    /// @notice Gets price of credits batch in a specific token
    /// @param token The address of the token
    /// @return price The price of the credits batch in the specified token
    function getPrice(IERC20 token) external view override returns (uint256 price) {
        (bool accepted, uint256 price_) = _prices.tryGet(address(token));
        require(accepted, TokenIsNotAccepted(token));
        return price_;
    }

    /// @notice Gets all supported tokens for payment
    /// @return tokens The list of supported tokens addresses
    function getSupportedTokens() external view override returns (address[] memory tokens) {
        return _prices.keys();
    }

    /// @notice Checks if a token is accepted for payment
    /// @param token The address of the token
    /// @return accepted True if the token is accepted, false otherwise
    function isTokenAccepted(IERC20 token) external view override returns (bool accepted) {
        return _prices.contains(address(token));
    }

    // Public

    /// @notice Converts schain name to schain hash
    /// @param schainName The name of the schain
    /// @return schainHash The hash of the schain name
    function toSchainHash(string memory schainName) public pure override returns (SchainHash schainHash) {
        return SchainHash.wrap(keccak256(abi.encodePacked(schainName)));
    }

    // Private

    /// @notice Get payment ID next after the provided one
    /// @param id The payment ID
    /// @return next The next payment ID
    function _next(PaymentId id) private pure returns (PaymentId next) {
        return PaymentId.wrap(PaymentId.unwrap(id) + 1);
    }
}
