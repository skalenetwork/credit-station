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
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ILedger } from "./interfaces/ILedger.sol";
import { PaymentId } from "./interfaces/types.sol";


/// @title Ledger contracts conducts credit fulfillment and stores history
/// @author Dmytro Stebaiev
/// @notice This contract is responsible for sending credits to purchasers
contract Ledger is AccessManaged, ILedger {
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address payable;

    EnumerableSet.UintSet private _fulfilledPayments;

    /// @notice Emitted when a payment is fulfilled
    /// @param payment The payment ID
    /// @param purchaser The address of the purchaser
    /// @param amount The amount sent
    event PaymentFulfilled(PaymentId payment, address purchaser, uint256 amount);

    error PaymentIsAlreadyFulfilled(PaymentId payment);

    /// @notice Constructor
    /// @param managerAddress The address of the Access Manager contract
    constructor(address managerAddress)
        AccessManaged(managerAddress)
    {
        assert(_fulfilledPayments.length() == 0);
    }

    // External

    /// @notice Send credits to the purchaser
    /// @param payment The payment ID
    /// @param purchaser The address purchased credits will be sent to
    function fulfill(PaymentId payment, address payable purchaser) external payable restricted override {
        require(_fulfilledPayments.add(PaymentId.unwrap(payment)), PaymentIsAlreadyFulfilled(payment));
        emit PaymentFulfilled(payment, purchaser, msg.value);
        purchaser.sendValue(msg.value);
    }

    // External view

    /// @notice Checks if a payment has been fulfilled
    /// @param payment The payment ID
    /// @return fulfilled True if the payment has been fulfilled, false otherwise
    function isFulfilled(PaymentId payment) external view override returns (bool fulfilled) {
        return _fulfilledPayments.contains(PaymentId.unwrap(payment));
    }
}
