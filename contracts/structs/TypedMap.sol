// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   TypedMap.sol - credit-station
 *   Copyright (C) 2026-Present SKALE Labs
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


/// @title Typed Map
/// @author Eduardo Vasques
/// @notice A library for Custom Typed mappings
library TypedMap {
    using EnumerableSet for EnumerableSet.UintSet;

    struct AddressToPaymentIdArrayMap {
        mapping(address key => PaymentId[] paymentIds) inner;
    }

    function add(
        AddressToPaymentIdArrayMap storage map,
        address key,
        PaymentId value
    ) internal {
        map.inner[key].push(value);
    }

    function at(
        AddressToPaymentIdArrayMap storage map,
        address key,
        uint256 index
    ) internal view returns (PaymentId paymentId) {
        return map.inner[key][index];
    }

    function length(
        AddressToPaymentIdArrayMap storage map,
        address key
    ) internal view returns (uint256 size) {
        return map.inner[key].length;
    }

    function values(
        AddressToPaymentIdArrayMap storage map,
        address key,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (PaymentId[] memory paymentIds) {
        uint256 len = map.inner[key].length;

        uint256 end = endIndex > len ? len : endIndex;
        uint256 resultLength = end - startIndex;
        paymentIds = new PaymentId[](resultLength);

        for (uint256 i = 0; i < resultLength; ) {
            paymentIds[i] = map.inner[key][startIndex + i];
            unchecked {
                ++i;
            }
        }
    }
}
