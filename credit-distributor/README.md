# credit-distributor

`credit-distributor` is a service that listens for `PaymentReceived` events on the mainnet `CreditStation` contract and fulfills the corresponding payments on the schain `Ledger` contract.

### Usage

#### Configuration

Configuration is loaded from a local TOML file.

1. Create your config:

```bash
cp config.toml.example config.toml
```

2. Edit `config.toml` for your environment.

See `config.toml.example` for the full list of required/optional settings and their meaning.

#### Running the service

Run the service:

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
