# credit-distributor

Fulfills `CreditStation` payments made on one or more source chains (the **sources**) through the `Ledger` on one SKALE chain (the **destination**).

Each cycle, per source, it reads `getLastPaymentId()` at the source's `block_tag`. When nothing is new, that single call is the whole cycle. Otherwise it reads `paymentsInfo(id)` for every new id. Payments to `schain_name` are fulfilled with `credits * 10**18` wei, others only move the cursor, and state is saved after every id.

## Configuration

Copy `config.toml.example` to `config.toml` with one `[[sources]]` entry per `CreditStation` deployment. Set `block_tag` to `finalized` on Ethereum, `safe` on Base and `latest` on SKALE chains. Payment ids carry `source_id` in their top byte (`CreditStation.setPaymentIdOffset`), so sources never collide on the `Ledger`. The first id processed is `source_id << 248 | start_offset`.

The signing key is read from `key_file` (a compose secret by default). Keep only a small float on it. A leaked key can drain the float and mark pending or future payment ids fulfilled: revoke its role on the `Ledger` access manager, then pay by hand every `PaymentFulfilled` whose purchaser or amount differs from `paymentsInfo(id)` on the source.

## State

`state.json` on the `state` volume binds the destination and each source to a chain id and contract, and holds each source's `next_id` and the `parked` payments, with ids as decimal integers. A destination mismatch stops the distributor, a source mismatch blocks that source.

## Failures

| Case | Log | Effect |
| --- | --- | --- |
| Payment already fulfilled | WARNING | skipped |
| Recipient rejects the value, or payment above `max_credits_per_payment` | ERROR `parked payment` | recorded in `parked`, cursor moves on |
| Agent balance below the payment, or `fulfill` reverts for the agent itself (role revoked) | ERROR `blocked` | source retried next cycle |
| Id gap or rewind (`setPaymentIdOffset` moved) | ERROR `blocked` | set `next_id` by hand past the change |
| RPC errors, receipt timeout | WARNING | source retried next cycle |

Alert on `ERROR credit_distributor` lines and on `already fulfilled` warnings. skale.py logs transient dry run failures at ERROR under its own logger. RPC errors log the full endpoint URL, so treat the container logs like `config.toml`.

To replay a parked payment, raise `max_credits_per_payment` first if it was over the cap and run `docker compose stop`. As root, edit `state.json` in the `state` volume: set that source's `next_id` to the parked id and remove its `parked` entry, then run `docker compose start`. Fulfilled payments in between are skipped, and other parked ones are retried.

## Running

Put the hex private key in `distributor_key`, then make it and the config (endpoints often carry provider keys) readable by the container user only:

```bash
sudo chown 65532 distributor_key config.toml && sudo chmod 0400 distributor_key config.toml
docker compose up -d --build
```

## Development

Set `key_file` and `state_file` in `config.toml` to local paths. Tests need `yarn compile && yarn hardhat node --port 8547` running from the repository root, and use `config.toml.example` as their base config.

```bash
uv sync
CONFIG_FILE=config.toml uv run credit-distributor
uv run ruff check && uv run ruff format --check && uv run mypy src tests
uv run pytest
```
