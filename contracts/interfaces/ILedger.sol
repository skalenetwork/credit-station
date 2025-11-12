// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ILedger.sol - credit-station
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

import { PaymentId } from "./types.sol";

/// @title Ledger Interface
/// @author Dmytro Stebaiev
/// @notice Interface of the Ledger contract
interface ILedger {
    /// @notice Send credits to the purchaser
    /// @param payment The payment ID
    /// @param purchaser The address of the purchaser
    function fulfill(PaymentId payment, address payable purchaser) external payable;
    /// @notice Checks if a payment is fulfilled
    /// @param payment The payment ID
    /// @return fulfilled True if the payment is fulfilled, false otherwise
    function isFulfilled(PaymentId payment) external view returns (bool fulfilled);
}
