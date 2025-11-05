// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Token.sol - credit-station
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

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title IMintable
/// @author Dmytro Stebaiev
/// @notice Interface for mintable tokens
interface IMintable {
    /// @notice Mints new tokens
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external;
}

/// @title Test ERC20 Token
/// @author Dmytro Stebaiev
/// @notice This is a simple ERC20 token for testing purposes
contract Token is ERC20, IMintable {
    /// @notice Creates a new ERC20 token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Mints new tokens
    /// @dev No restriction on minting for testing purposes
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external override {
        _mint(to, amount);
    }
}
