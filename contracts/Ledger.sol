// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Ledger.sol - credit-station
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

import {
    AccessManaged
} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import { ILedger } from "./interfaces/ILedger.sol";
import { Credit } from "./interfaces/types.sol";


/// @title Ledger contracts conducts credit fulfillment and stores history
/// @author Dmytro Stebaiev
/// @notice This contract is responsible for sending credits to purchasers
contract Ledger is AccessManaged, ILedger {
    /// @notice Number of credits to send to the purchaser
    Credit public creditsNumber;

    error NotImplemented();

    /// @notice Constructor
    /// @param managerAddress The address of the Access Manager contract
    constructor(address managerAddress)
        AccessManaged(managerAddress)
    {
        creditsNumber = Credit.wrap(10 ether);
    }

    /// @notice Send credits to the purchaser
    function fulfill() external override {
        revert NotImplemented();
    }
}
