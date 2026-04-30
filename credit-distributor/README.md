# credit-distributor

`credit-distributor` watches `PaymentReceived` events on one or more `CreditStation` deployments (the **sources**) and fulfills each payment on a single **destination** schain `Ledger`.

Each source is an independent `CreditStation` deployment on its own chain, initialized with a unique on-chain `sourceId` (set via `setPaymentIdOffset`) so payment IDs never collide. The distributor reads from every source sequentially each cycle and forwards `event.value` (wei) as the native amount to the purchaser on the destination schain.

### Usage

#### Configuration

Configuration is loaded from a local TOML file.

1. Create your config:

   ```bash
   cp config.toml.example config.toml
   ```

2. Edit `config.toml`:

   - `[general]` — destination `schain_name` and the distributor's `eth_private_key` (used to call `Ledger.fulfill` on the destination schain).
   - `[destination]` — destination schain `endpoint` and `Ledger` `contract` address.
   - `[[sources]]` — one entry per `CreditStation` deployment. Repeat the block for each source chain. Each needs a unique `name` (used as a state-file key), the source-chain `endpoint`, the `CreditStation` `contract` address, and an initial `from_block` to scan from.

See `config.toml.example` for a complete annotated sample with two sources.

The distributor maintains per-source progress in `state.json` (path configurable via `[general].state_file`). Adding a new source later just appends a `[[sources]]` block and starts at its configured `from_block`; existing sources keep their stored progress.

#### Running the service

```bash
docker compose up -d --build
```

### Development

#### Install dependencies

```bash
uv sync --all-extras
```

#### Run locally

```bash
uv run python src/main.py
```

#### Lint code

```bash
uv run ruff check . --fix
```
