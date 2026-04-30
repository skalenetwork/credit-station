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

from src.configs import Config, Source, get_config
from src.state import State, StateManager

logger = logging.getLogger(__name__)


def run_distributor() -> None:
    config = get_config()
    state_manager = StateManager(state_file=config.general.state_file)
    state = state_manager.load({s.name: s.from_block for s in config.sources})

    schain_web3 = init_web3(config.destination.endpoint)
    schain_wallet = Web3Wallet(config.general.eth_private_key, schain_web3)
    schain_cs = SchainCreditStation(
        config.destination.endpoint, config.destination.contract, schain_wallet
    )
    source_clients = {
        source.name: MainnetCreditStation(source.endpoint, source.contract)
        for source in config.sources
    }

    while True:
        logger.info('Starting credit distribution cycle')
        for source in config.sources:
            try:
                state = distribute_credits_for_source(
                    source, source_clients[source.name], schain_cs, config, state
                )
                state_manager.save(state)
            except Exception as e:
                logger.exception(
                    f'Error processing source {source.name!r}: {e}; continuing with next'
                )
        logger.info(f'Sleeping for {config.agent.loop_sleep} seconds before next cycle')
        sleep(config.agent.loop_sleep)


def distribute_credits_for_source(
    source: Source,
    mainnet_cs: MainnetCreditStation,
    schain_cs: SchainCreditStation,
    config: Config,
    state: State,
) -> State:
    from_block = state.from_blocks[source.name]
    logger.info(f'[{source.name}] Fetching events from block {from_block}')
    all_events = mainnet_cs.credit_station.get_payment_received_events(
        from_block=from_block, schain_name=config.general.schain_name
    )
    for event in all_events:
        fulfill_payment(source, event, schain_cs)

    if all_events:
        state.from_blocks[source.name] = all_events[-1]['block_number'] + 1
    else:
        logger.info(f'[{source.name}] No new PaymentReceived events found.')
    return state


def fulfill_payment(
    source: Source,
    event: PaymentReceivedEvent,
    schain_cs: SchainCreditStation,
) -> None:
    payment_id = event['payment_id']
    logger.info(f'[{source.name}] Checking payment: {payment_id}')
    is_fulfilled = schain_cs.ledger.is_fulfilled(payment_id)
    if not is_fulfilled:
        logger.info(f'[{source.name}] Fulfilling payment: {payment_id}')
        schain_cs.ledger.fulfill(payment_id, event['to_address'], value=event['value'])
        logger.info(f'[{source.name}] Payment {payment_id} fulfilled successfully.')
    else:
        logger.debug(f'[{source.name}] Payment {payment_id} is already fulfilled.')


if __name__ == '__main__':
    init_default_logger()
    run_distributor()
