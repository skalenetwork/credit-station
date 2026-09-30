import json
import os
import tomllib
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pytest
from eth_account import Account
from eth_typing import ChecksumAddress
from skale.types.credit_station import PaymentId
from web3 import Web3
from web3.contract import Contract
from web3.types import RPCEndpoint

from credit_distributor import SOURCE_ID_SHIFT, Binding, Config, Cursor, Distributor, InvariantError

ENDPOINT = os.environ.get('ENDPOINT', 'http://127.0.0.1:8547')
ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT.parent / 'artifacts' / 'contracts'
EXAMPLE = tomllib.loads((ROOT / 'config.toml.example').read_text())
SOURCE = EXAMPLE['sources'][0]
NAME = SOURCE['name']
SOURCE_ID = SOURCE['source_id']
FIRST = SOURCE_ID << SOURCE_ID_SHIFT | SOURCE['start_offset']
SCHAIN = EXAMPLE['schain_name']
CAP = EXAMPLE['max_credits_per_payment']
VERSION = '1.0.0-develop.5'
AGENT_KEY = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
AGENT = Account.from_key(AGENT_KEY).address
FULFILL_AGENT_ROLE = 1
RECIPIENT, REJECTING, BOMB = (Web3.to_checksum_address(f'0x{digit * 40}') for digit in '123')
VM = 'Error: VM Exception while processing transaction: reverted with custom error'


@dataclass(frozen=True)
class Chain:
    w3: Web3
    manager: Contract
    station: Contract
    ledger: ChecksumAddress
    token: ChecksumAddress

    def rpc(self, method: str, *params: object) -> Any:
        return self.w3.provider.make_request(RPCEndpoint(method), list(params))['result']

    def buy(self, credits: int, to: str = RECIPIENT, schain: str = SCHAIN) -> PaymentId:
        self.station.functions.buy(schain, to, self.token, credits).transact()
        return PaymentId(self.station.functions.getLastPaymentId().call())

    def fund(self, credits: int) -> None:
        self.rpc('hardhat_setBalance', AGENT, hex(Web3.to_wei(credits, 'ether')))

    def observe(self) -> tuple[int, int]:
        return self.w3.eth.get_balance(RECIPIENT), self.w3.eth.get_transaction_count(AGENT)


Cycle = Callable[[Distributor], list[str]]
Step = Callable[[Chain], object]


def deploy(w3: Web3, name: str, *args: object) -> Contract:
    artifact = json.loads(next(ARTIFACTS.rglob(f'{name}.json')).read_text())
    factory = w3.eth.contract(abi=artifact['abi'], bytecode=artifact['bytecode'])
    receipt = w3.eth.get_transaction_receipt(factory.constructor(*args).transact())
    return factory(receipt['contractAddress'])


def cursor(distributor: Distributor) -> int:
    return distributor.state.sources[NAME].next_id


@pytest.fixture(scope='session')
def chain() -> Chain:
    w3 = Web3(Web3.HTTPProvider(ENDPOINT))
    w3.eth.default_account = owner = w3.eth.accounts[0]
    manager = deploy(w3, 'CreditStationAccessManager', owner)
    station = deploy(w3, 'CreditStation', manager.address, owner)
    ledger = deploy(w3, 'Ledger', manager.address)
    token = deploy(w3, 'Token', 'Token', 'TKN')
    selector = Web3.keccak(text='fulfill(uint256,address)')[:4]
    for function in (
        manager.functions.setTargetFunctionRole(ledger.address, [selector], FULFILL_AGENT_ROLE),
        manager.functions.grantRole(FULFILL_AGENT_ROLE, AGENT, 0),
        station.functions.setVersion(VERSION),
        ledger.functions.setVersion(VERSION),
        station.functions.setPrice(token.address, 1),
        station.functions.setPaymentIdOffset(SOURCE_ID, SOURCE['start_offset']),
        token.functions.mint(owner, 10**24),
        token.functions.approve(station.address, 2**256 - 1),
    ):
        function.transact()
    chain = Chain(w3, manager, station, ledger.address, token.address)
    chain.rpc('hardhat_setCode', REJECTING, '0x5f5ffd')
    chain.rpc('hardhat_setCode', BOMB, '0x622600005ff3')
    return chain


@pytest.fixture(autouse=True)
def snapshot(chain: Chain) -> Iterator[None]:
    snapshot_id = chain.rpc('evm_snapshot')
    yield
    chain.rpc('evm_revert', snapshot_id)


@pytest.fixture
def distributor(chain: Chain, tmp_path: Path) -> Distributor:
    (tmp_path / 'key').write_text(AGENT_KEY)
    config = EXAMPLE | {
        'key_file': tmp_path / 'key',
        'state_file': tmp_path / 'state.json',
        'destination': {'endpoint': ENDPOINT, 'contract': chain.ledger},
        'sources': [SOURCE | {'endpoint': ENDPOINT, 'contract': chain.station.address}],
    }
    return Distributor(Config.model_validate(config))


@pytest.fixture
def cycle(caplog: pytest.LogCaptureFixture) -> Cycle:
    def run(distributor: Distributor) -> list[str]:
        caplog.clear()
        distributor.cycle()
        return [
            f'{r.levelname} {r.message}' for r in caplog.records if r.name == 'credit_distributor'
        ]

    return run


@pytest.mark.parametrize(
    ('credits', 'to', 'reason'),
    [
        (5, RECIPIENT, None),
        (5, REJECTING, f"DryRunRevertError: execution reverted: {VM} 'FailedCall()'"),
        (5, BOMB, 'DryRunRevertError: execution reverted: Transaction ran out of gas'),
        (CAP + 1, RECIPIENT, f'{CAP + 1} credits exceed the cap of {CAP}'),
    ],
    ids=['fulfilled', 'rejecting', 'out_of_gas', 'over_cap'],
)
def test_cycle(
    chain: Chain, distributor: Distributor, cycle: Cycle, credits: int, to: str, reason: str | None
) -> None:
    payment, foreign, later = chain.buy(credits, to), chain.buy(5, schain='other'), chain.buy(3)
    balance, nonce = chain.observe()
    logs = cycle(distributor)
    parked = {payment: reason} if reason else {}
    paid = not parked
    fulfilled = [distributor.ledger.is_fulfilled(p) for p in (payment, foreign, later)]
    assert logs == [f'ERROR {NAME}: parked payment {p:#x}: {r}' for p, r in parked.items()]
    assert chain.observe() == (balance + Web3.to_wei(3 + credits * paid, 'ether'), nonce + 1 + paid)
    assert fulfilled == [paid, False, True]
    assert distributor.state.parked == parked
    assert cursor(distributor) == later + 1
    assert Distributor(distributor.config).state == distributor.state


@pytest.mark.parametrize(
    ('block', 'unblock', 'message'),
    [
        (lambda c: c.fund(1), lambda c: c.fund(10), f'agent balance is below {5 * 10**18} wei'),
        (
            lambda c: c.manager.functions.revokeRole(FULFILL_AGENT_ROLE, AGENT).transact(),
            lambda c: c.manager.functions.grantRole(FULFILL_AGENT_ROLE, AGENT, 0).transact(),
            f'fulfill reverts for the agent too: execution reverted: {VM} '
            f'\'AccessManagedUnauthorized("{AGENT}")\'',
        ),
    ],
    ids=['balance', 'role'],
)
def test_blocks_until_fixed(
    chain: Chain, distributor: Distributor, cycle: Cycle, block: Step, unblock: Step, message: str
) -> None:
    block(chain)
    payment = chain.buy(5)
    assert cycle(distributor) == [f'ERROR {NAME}: blocked: {message}']
    assert cursor(distributor) == payment
    unblock(chain)
    assert cycle(distributor) == []
    assert distributor.ledger.is_fulfilled(payment)


@pytest.mark.parametrize(
    ('source_id', 'offset', 'message'),
    [
        (SOURCE_ID + 1, 2, f'payment {FIRST + 1:#x} is missing'),
        (SOURCE_ID, 1, f'last payment {FIRST - 1:#x} is before {FIRST + 1:#x}'),
    ],
    ids=['gap', 'rewind'],
)
def test_blocks_broken_sequence(
    chain: Chain, distributor: Distributor, cycle: Cycle, source_id: int, offset: int, message: str
) -> None:
    chain.buy(5)
    assert cycle(distributor) == []
    chain.station.functions.setPaymentIdOffset(source_id, offset).transact()
    assert cycle(distributor) == [f'ERROR {NAME}: blocked: {message}']
    assert cursor(distributor) == FIRST + 1


def test_restart_does_not_pay_twice(chain: Chain, distributor: Distributor, cycle: Cycle) -> None:
    state_file = distributor.config.state_file
    chain.buy(2)
    cycle(distributor)
    saved = state_file.read_bytes()
    payment = chain.buy(3)
    cycle(distributor)
    before = chain.observe()
    state_file.write_bytes(saved)
    restarted = Distributor(distributor.config)
    assert cycle(restarted) == [f'WARNING Payment {payment:#x} is already fulfilled']
    assert chain.observe() == before
    assert restarted.state == distributor.state


def test_replay_clears_parked(chain: Chain, distributor: Distributor, cycle: Cycle) -> None:
    payment = chain.buy(CAP + 1)
    cycle(distributor)
    distributor.state.sources[NAME].next_id = payment
    distributor.state.save(distributor.config.state_file)
    replay = Distributor(distributor.config.model_copy(update={'max_credits_per_payment': CAP + 1}))
    assert cycle(replay) == []
    assert replay.ledger.is_fulfilled(payment)
    assert replay.state.parked == {}


def test_rejects_foreign_state(chain: Chain, distributor: Distributor, cycle: Cycle) -> None:
    here = Binding(chain_id=chain.w3.eth.chain_id, contract=chain.station.address)
    other = Binding(chain_id=here.chain_id + 1, contract=here.contract)
    distributor.state.sources[NAME] = Cursor(binding=other, next_id=PaymentId(FIRST))
    assert cycle(distributor) == [f'ERROR {NAME}: blocked: state is bound to {other}, not {here}']
    distributor.state.destination = other
    distributor.state.save(distributor.config.state_file)
    with pytest.raises(InvariantError, match='state is bound'):
        Distributor(distributor.config)
