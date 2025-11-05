// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ICreditStation.sol - credit-station
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

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { SchainHash } from "./types.sol";

/// @title Credit Station Interface
/// @author Dmytro Stebaiev
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
    /// @notice Sets the receiver address
    /// @param newReceiver The new receiver address
    function setReceiver(address newReceiver) external;
    /// @notice Gets price of credits batch in a specific token
    /// @param token The address of the token
    /// @return price The price of the credits batch in the specified token
    function getPrice(IERC20 token) external view returns (uint256 price);
    /// @notice Gets all supported tokens for payment
    /// @return tokens The list of supported tokens addresses
    function getSupportedTokens() external view returns (IERC20[] memory tokens);
    /// @notice Checks if a token is accepted for payment
    /// @param token The address of the token
    /// @return accepted True if the token is accepted, false otherwise
    function isTokenAccepted(IERC20 token) external view returns (bool accepted);
    /// @notice Converts schain name to schain hash
    /// @param schainName The name of the schain
    /// @return schainHash The hash of the schain name
    function toSchainHash(string memory schainName) external pure returns (SchainHash schainHash);
}
