// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   CreditStation.sol - credit-station
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

import {
    AccessManaged
} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ICreditStation, IERC20 } from "./interfaces/ICreditStation.sol";
import { PaymentId, SchainHash } from "./interfaces/types.sol";


/// @title Credit Station
/// @author Dmytro Stebaiev
/// @notice This contract is responsible for receiving payments for credits.
contract CreditStation is AccessManaged, ICreditStation {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice Address that receives the payments for credits
    address public receiver;
    PaymentId private _nextPaymentId = PaymentId.wrap(1);
    EnumerableSet.UintSet private _pendingPayments;
    EnumerableMap.AddressToUintMap private _prices;

    /// @notice Emitted when a payment is received
    /// @param id The payment ID
    /// @param schainHash The hash of the target schain name
    /// @param from The address of the payer
    /// @param to The address of the credits receiver
    /// @param tokenAddress The address of the token used for payment
    event PaymentReceived(
        PaymentId id,
        SchainHash schainHash,
        address from,
        address to,
        IERC20 tokenAddress
    );

    error TokenIsNotAccepted(IERC20 token);
    error TokenTransferFailed(IERC20 token, address from, uint256 amount);

    /// @notice Constructor
    /// @param accessManagerAddress The address of the Access Manager contract
    /// @param initialReceiver The initial receiver of the payments
    constructor(address accessManagerAddress, address initialReceiver) AccessManaged(accessManagerAddress) {
        receiver = initialReceiver;
    }

    // External

    /// @notice Pay to get credits on an schain
    /// @param schainName The name of the schain
    /// @param purchaser The address purchased credits will be sent to
    /// @param token The address of the token to pay with
    function buy(
        string calldata schainName,
        address purchaser,
        IERC20 token
    )
        external
        override
    {
        (bool accepted, uint256 price) = _prices.tryGet(address(token));
        require(accepted, TokenIsNotAccepted(token));
        require(token.transferFrom(msg.sender, receiver, price), TokenTransferFailed(token, msg.sender, price));
        PaymentId currentPaymentId = _nextPaymentId;
        _nextPaymentId = _next(_nextPaymentId);

        emit PaymentReceived({
            id: currentPaymentId,
            schainHash: toSchainHash(schainName),
            from: msg.sender,
            to: purchaser,
            tokenAddress: token
        });
    }

    // Public

    /// @notice Converts schain name to schain hash
    /// @param schainName The name of the schain
    /// @return schainHash The hash of the schain name
    function toSchainHash(string memory schainName) public pure override returns (SchainHash schainHash) {
        return SchainHash.wrap(keccak256(abi.encodePacked(schainName)));
    }

    // Private

    /// @notice Get payment ID next after the provided one
    /// @param id The payment ID
    /// @return next The next payment ID
    function _next(PaymentId id) private pure returns (PaymentId next) {
        return PaymentId.wrap(PaymentId.unwrap(id) + 1);
    }
}
