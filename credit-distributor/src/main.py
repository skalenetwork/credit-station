#   -*- coding: utf-8 -*-
#
#   This file is part of credit-distributor.
#
#   Copyright (C) 2025 SKALE Labs
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

import logging
from time import sleep

from skale import MainnetCreditStation, SchainCreditStation
from skale.types.credit_station import PaymentReceivedEvent
from skale.utils.helper import init_default_logger
from skale.utils.web3_utils import init_web3
from skale.wallets import Web3Wallet

from src.configs import Config, get_config
from src.state import State, StateManager

logger = logging.getLogger(__name__)


def run_distributor() -> None:
    config = get_config()
    state_manager = StateManager(state_file=config.state_file)
    state = state_manager.load(config.from_block)

    schain_web3 = init_web3(config.schain_endpoint)
    schain_wallet = Web3Wallet(config.eth_private_key, schain_web3)

    mainnet_cs = MainnetCreditStation(config.mainnet_endpoint, config.mainnet_contracts)
    schain_cs = SchainCreditStation(config.schain_endpoint, config.schain_contracts, schain_wallet)
    while True:
        try:
            logging.info('Starting credit distribution cycle')
            state = distribute_credits(mainnet_cs, schain_cs, config, state)
            state_manager.save(state)
            logger.info(f'Sleeping for {config.agent_loop_sleep} seconds before next cycle')
            sleep(config.agent_loop_sleep)
        except Exception as e:
            logging.exception(f'Error during credit distribution cycle: {e}')
            logger.info(f'Sleeping for {config.agent_exception_sleep} seconds before retrying')
            sleep(config.agent_exception_sleep)


def distribute_credits(
    mainnet_cs: MainnetCreditStation,
    schain_cs: SchainCreditStation,
    config: Config,
    state: State,
) -> State:
    all_events = mainnet_cs.credit_station.get_payment_received_events(
        from_block=state.from_block, schain_name=config.schain_name
    )
    last_block = state.from_block
    for event in all_events:
        fulfill_payment(event, schain_cs, config)

    last_block_with_event = 0
    if len(all_events) != 0:
        last_block_with_event = all_events[-1]['block_number']
    else:
        logger.info('No new PaymentReceived events found.')
    state.from_block = max(last_block, last_block_with_event + 1)
    return state


def fulfill_payment(
    event: PaymentReceivedEvent, schain_cs: SchainCreditStation, config: Config
) -> None:
    logger.info(f'Checking payment: {event["payment_id"]}')
    is_fulfilled = schain_cs.ledger.is_fulfilled(event['payment_id'])
    if not is_fulfilled:
        logger.info(f'Fulfilling payment: {event["payment_id"]}')
        schain_cs.ledger.fulfill(
            event['payment_id'], event['to_address'], value=config.payment_value_wei
        )
        logger.info(f'Payment {event["payment_id"]} fulfilled successfully.')
    else:
        logger.debug(f'Payment {event["payment_id"]} is already fulfilled.')


if __name__ == '__main__':
    init_default_logger()
    run_distributor()
