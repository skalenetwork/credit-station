# credit-distributor

`credit-distributor` is a service that listens for `PaymentReceived` events on the mainnet `CreditStation` contract and fulfills the corresponding payments on the schain `Ledger` contract.

### Usage

#### Required env parameters

```bash
MAINNET_ENDPOINT= # endpoint of the mainnet network, where credit-station-mainnet is deployed
SCHAIN_ENDPOINT= # endpoint of the schain, where credit-station-schain is deployed
MAINNET_CONTRACTS= # alias or address of the credit-station-mainnet contract
SCHAIN_CONTRACTS= # alias or address of the credit-station-schain contract
SCHAIN_NAME= # name of the schain (from skale-manager contracts)
FROM_BLOCK= # block number to start processing events from
ETH_PRIVATE_KEY= # private key of the account used to fulfill payments on schain (must have native currency on schain and agent role)
```

#### Optional env parameters

```bash
STATE_FILE= # path to the state file (default: ./state.json)
AGENT_LOOP_SLEEP= # sleep time between iterations of the agent loop in seconds (default: 120)
AGENT_EXCEPTION_SLEEP= # sleep time after an exception in seconds (default: 10)
PAYMENT_VALUE_ETH= # value of each payment to fulfill in ETH (default: 1)
```

#### Running the service

1. Export all required env parameters:

```bash
export $(grep -v '^#' .env | xargs)
```

2. Run the service:

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
