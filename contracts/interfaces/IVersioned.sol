// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IVersioned.sol - credit-station
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


/// @title IVersioned
/// @author Dmytro Stebaiev
/// @notice Interface for versioned contracts
interface IVersioned {
    /// @notice Emitted when the version is changed
    /// @param oldVersion The old version string
    /// @param newVersion The new version string
    event VersionChanged(string oldVersion, string newVersion);

    /// @notice Sets the version of the contract
    /// @param newVersion The new version string
    function setVersion(string memory newVersion) external;
    /// @notice Returns the version of the contract
    /// @return currentVersion The version string
    function version() external view returns (string memory currentVersion);

}
