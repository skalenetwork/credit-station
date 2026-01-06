// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   TypedMap.sol - credit-station
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

import { TypedSet } from "./TypedSet.sol";


/// @title Typed Map
/// @author Eduardo Vasques
/// @notice A library for Custom Typed mappings
library TypedMap {
    using EnumerableSet for EnumerableSet.UintSet;
    using TypedSet for TypedSet.PaymentIdSet;
    struct AddressToPaymentIdSetMap {
        mapping(address key => TypedSet.PaymentIdSet set) inner;
    }

    function add(
        AddressToPaymentIdSetMap storage map,
        address key,
        PaymentId value
    ) internal returns (bool result) {
        return map.inner[key].add(value);
    }

    function at(
        AddressToPaymentIdSetMap storage map,
        address key,
        uint256 index
    ) internal view returns (PaymentId paymentId) {
        uint256 rawValue = map.inner[key].inner.at(index);
        return PaymentId.wrap(rawValue);
    }

    function length(
        AddressToPaymentIdSetMap storage map,
        address key
    ) internal view returns (uint256 size) {
        return map.inner[key].length();
    }

    function values(
        AddressToPaymentIdSetMap storage map,
        address key,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (PaymentId[] memory ids) {
        return map.inner[key].values(startIndex, endIndex);
    }
}
