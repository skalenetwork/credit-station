// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   TypedSet.sol - credit-station
 *   Copyright (C) 2025-Present SKALE Labs
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

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { PaymentId } from "../interfaces/types.sol";

/// @title Typed Set
/// @author Eduardo Vasques
/// @notice A library for Custom Typed Enumerable Sets
library TypedSet {
    using EnumerableSet for EnumerableSet.UintSet;

    struct PaymentIdSet {
        EnumerableSet.UintSet inner;
    }

    function add(
        PaymentIdSet storage set,
        PaymentId value
    ) internal returns (bool result) {
        return set.inner.add(PaymentId.unwrap(value));
    }

    function length(
        PaymentIdSet storage set
    ) internal view returns (uint256 size) {
        return set.inner.length();
    }

    function values(
        PaymentIdSet storage set,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (PaymentId[] memory paymentIds) {
        uint256 setLength = set.inner.length();

        uint256 end = endIndex > setLength ? setLength : endIndex;
        uint256 resultLength = end - startIndex;
        paymentIds = new PaymentId[](resultLength);

        for (uint256 i = 0; i < resultLength; ) {
            paymentIds[i] = PaymentId.wrap(set.inner.at(startIndex + i));
            unchecked {
                ++i;
            }
        }
    }
}
