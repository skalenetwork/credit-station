// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ICreditStation.sol - credit-station
 *   Copyright (C) 2025-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *   @author Eduardo Vasques
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

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { SchainHash, PaymentId, PaymentInfo } from "./types.sol";

/// @title Credit Station Interface
/// @author Dmytro Stebaiev
/// @author Eduardo Vasques
/// @notice Interface of the Credit Station contract
interface ICreditStation {
    /// @notice Pay to get credits on an schain
    /// @param schainName The name of the schain
    /// @param purchaser The address purchased credits will be sent to
    /// @param token The address of the token to pay with
    function buy(
        string calldata schainName,
        address purchaser,
        IERC20 token
    ) external;
    /// @notice Pauses the contract
    function pause() external;
    /// @notice Sets price of credits batch in a specific token
    /// @notice Setting price to 0 removes the token from accepted tokens list
    /// @param token The address of the token
    /// @param price The price of the credits batch in the specified token
    function setPrice(IERC20 token, uint256 price) external;
    /// @notice Sets the receiver address
    /// @param newReceiver The new receiver address
    function setReceiver(address newReceiver) external;
    /// @notice Unpauses the contract
    function unpause() external;
    /// @notice Gets the number of payments made by a user
    /// @param user The address of the buyer
    /// @return numberOfPayments returns the number of payments made by the user
    function getNumberOfPayments(
        address user
    ) external view returns (uint256 numberOfPayments);
    /// @notice Gets the last payment made by a user
    /// @param user The address of the buyer
    /// @return paymentId returns the last payment ID if there is one, reverts otherwise
    function getLastPayment(
        address user
    ) external view returns (PaymentId paymentId);
    /// @notice Gets the last paymentId made in the system
    /// @return paymentId returns the last payment ID made in the system
    function getLastPaymentId() external view returns (PaymentId paymentId);
    /// @notice Gets the payment IDs made by a user within a specific range (MAX 10_000 each query)
    /// @param user The address of the buyer
    /// @param startIndex The start index (inclusive) of the payments to get
    /// @param endIndex The end index (exclusive) of the payments to get
    /// @return payments returns a list of payment IDs if there are any, reverts otherwise
    function getPaymentIds(
        address user,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (PaymentId[] memory payments);
    /// @notice Gets payment information by its id
    /// @param paymentId The id of the payment
    /// @return payment returns a payment if there is one, reverts otherwise
    function getPaymentInfo(
        PaymentId paymentId
    ) external view returns (PaymentInfo memory payment);
    /// @notice Gets price of credits batch in a specific token
    /// @param token The address of the token
    /// @return price The price of the credits batch in the specified token
    function getPrice(IERC20 token) external view returns (uint256 price);
    /// @notice Gets all supported tokens for payment
    /// @return tokens The list of supported tokens addresses
    function getSupportedTokens() external view returns (address[] memory tokens);
    /// @notice Checks if a token is accepted for payment
    /// @param token The address of the token
    /// @return accepted True if the token is accepted, false otherwise
    function isTokenAccepted(IERC20 token) external view returns (bool accepted);
    /// @notice Converts schain name to schain hash
    /// @param schainName The name of the schain
    /// @return schainHash The hash of the schain name
    function toSchainHash(string memory schainName) external pure returns (SchainHash schainHash);
}
