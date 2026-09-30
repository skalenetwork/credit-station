#   This file is part of credit-distributor.
#
#   Copyright (C) 2025-Present SKALE Labs
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
import os
import time
import tomllib
from pathlib import Path
from typing import Annotated, Literal, Self

from eth_typing import ChecksumAddress, HexStr
from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator
from skale import MainnetCreditStation, SchainCreditStation
from skale.config import NO_SYNC_TS_DIFF
from skale.contracts.credit_station.credit_station import CreditStation
from skale.skale_base import SkaleBase
from skale.transactions.exceptions import DryRunRevertError, TransactionLogicError
from skale.types.credit_station import PaymentId, PaymentInfo
from skale.utils.helper import schain_name_to_hash
from skale.wallets import Web3Wallet
from skale_core.types import SchainName
from web3 import Web3

CONFIG_FILE = Path(os.environ.get('CONFIG_FILE', '/etc/credit-distributor/config.toml'))
SOURCE_ID_SHIFT = 248

logger = logging.getLogger(__name__)

Address = Annotated[ChecksumAddress, AfterValidator(Web3.to_checksum_address)]


class InvariantError(Exception):
    pass


class Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra='forbid', hide_input_in_errors=True)


class Deployment(Frozen):
    endpoint: str
    contract: Address

    def client[T: SkaleBase](self, cls: type[T]) -> T:
        return cls(self.endpoint, self.contract, ts_diff=NO_SYNC_TS_DIFF)


class Source(Deployment):
    name: str = Field(min_length=1)
    block_tag: Literal['finalized', 'safe', 'latest']
    source_id: int = Field(ge=0, le=255)
    start_offset: int = Field(ge=0, lt=1 << SOURCE_ID_SHIFT)


class Config(Frozen):
    schain_name: SchainName = Field(min_length=1)
    max_credits_per_payment: int = Field(gt=0)
    poll_seconds: int = Field(default=120, gt=0)
    key_file: Path = Path('/run/secrets/distributor_key')
    state_file: Path = Path('/state/state.json')
    destination: Deployment
    sources: tuple[Source, ...] = Field(min_length=1)

    @model_validator(mode='after')
    def check_unique(self) -> Self:
        for field in ('name', 'source_id'):
            if len({getattr(source, field) for source in self.sources}) < len(self.sources):
                raise ValueError(f'Duplicate source {field}')
        return self


class Binding(Frozen):
    chain_id: int
    contract: Address


class Cursor(BaseModel, extra='forbid'):
    binding: Binding
    next_id: PaymentId


class State(BaseModel, extra='forbid'):
    destination: Binding
    sources: dict[str, Cursor] = {}
    parked: dict[PaymentId, str] = {}

    def save(self, path: Path) -> None:
        tmp = path.with_name(f'{path.name}.tmp')
        with tmp.open('w') as file:
            file.write(self.model_dump_json(indent=2))
            file.flush()
            os.fsync(file)
        os.replace(tmp, path)


class Distributor:
    def __init__(self, config: Config) -> None:
        schain = config.destination.client(SchainCreditStation)
        schain.wallet = Web3Wallet(HexStr(config.key_file.read_text().strip()), schain.web3)
        self.config, self.ledger = config, schain.ledger
        binding = Binding(chain_id=schain.web3.eth.chain_id, contract=self.ledger.address)
        self.state = State(destination=binding)
        if config.state_file.exists():
            self.state = State.model_validate_json(config.state_file.read_bytes())
        if self.state.destination != binding:
            raise InvariantError(f'state is bound to {self.state.destination}, not {binding}')
        self.stations: dict[str, CreditStation] = {}

    def cycle(self) -> None:
        for source in self.config.sources:
            try:
                self.process(source)
            except InvariantError as error:
                logger.error('%s: blocked: %s', source.name, error)
            except Exception as error:
                logger.warning('%s: %r', source.name, error)

    def connect(self, source: Source) -> CreditStation:
        station = source.client(MainnetCreditStation).credit_station
        binding = Binding(chain_id=station.web3.eth.chain_id, contract=station.address)
        first = PaymentId(source.source_id << SOURCE_ID_SHIFT | source.start_offset)
        cursor = self.state.sources.setdefault(source.name, Cursor(binding=binding, next_id=first))
        if cursor.binding != binding:
            raise InvariantError(f'state is bound to {cursor.binding}, not {binding}')
        return station

    def process(self, source: Source) -> None:
        if source.name not in self.stations:
            self.stations[source.name] = self.connect(source)
        station, cursor = self.stations[source.name], self.state.sources[source.name]
        last = station.get_last_payment_id(source.block_tag)
        if last < cursor.next_id - 1:
            raise InvariantError(f'last payment {last:#x} is before {cursor.next_id:#x}')
        schain_hash = schain_name_to_hash(self.config.schain_name)
        for payment in map(PaymentId, range(cursor.next_id, last + 1)):
            info = station.get_payment_info(payment)
            if info is None:
                raise InvariantError(f'payment {payment:#x} is missing')
            if info.schain_hash == schain_hash and (reason := self.fulfill(payment, info)):
                self.state.parked[payment] = reason
                logger.error('%s: parked payment %#x: %s', source.name, payment, reason)
            cursor.next_id = PaymentId(payment + 1)
            self.state.save(self.config.state_file)

    def fulfill(self, payment: PaymentId, info: PaymentInfo) -> str | None:
        ledger, cap = self.ledger, self.config.max_credits_per_payment
        if ledger.is_fulfilled(payment):
            logger.warning('Payment %#x is already fulfilled', payment)
            return None
        if info.value > cap:
            return f'{info.value} credits exceed the cap of {cap}'
        value = Web3.to_wei(info.value, 'ether')
        if ledger.web3.eth.get_balance(ledger.wallet.address) < value:
            raise InvariantError(f'agent balance is below {value} wei')
        try:
            ledger.fulfill(payment, info.to_address, value=value, timeout=60)
        except TransactionLogicError as error:
            try:
                ledger.fulfill(payment, ledger.wallet.address, value=value, dry_run_only=True)
            except DryRunRevertError as probe:
                raise InvariantError(f'fulfill reverts for the agent too: {probe.message}')
            return f'{type(error).__name__}: {error.message}'[:200]
        logger.info('Fulfilled payment %#x: %d credits to %s', payment, info.value, info.to_address)
        return None


def main() -> None:
    logging.basicConfig(level='INFO', format='%(asctime)s %(levelname)s %(name)s: %(message)s')
    try:
        distributor = Distributor(Config.model_validate(tomllib.loads(CONFIG_FILE.read_text())))
        while True:
            distributor.cycle()
            time.sleep(distributor.config.poll_seconds)
    except Exception:
        logger.exception('Distributor stopped')
        raise SystemExit(1)
