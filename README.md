# Credit Station

<div align="center">

[![License](https://img.shields.io/github/license/skalenetwork/credit-station.svg)](LICENSE)
[![Discord](https://img.shields.io/discord/534485763354787851.svg)](https://discord.gg/skale)
[![Build Status](https://github.com/skalenetwork/credit-station/actions/workflows/test.yml/badge.svg)](https://github.com/skalenetwork/credit-station/actions)
[![codecov](https://codecov.io/gh/skalenetwork/credit-station/branch/develop/graph/badge.svg)](https://codecov.io/gh/skalenetwork/credit-station)

<p>On-chain payment gateway for purchasing SKALE credits on mainnet and fulfilling them on SKALE chains.</p>

</div>


## Introduction

`credit-station` is the payment entry point for SKALE credit purchases.
It receives payments on mainnet and coordinates credit fulfillment on SKALE
chains via the `Ledger` contract deployed on the SKALE chain side.

Together with the `credit-distributor` off-chain agent, it provides a simple way to buy credits to interact with skale chains.

**Core Capabilities:**

- **Mainnet credit payments:** Accepts ERC-20 payments to buy credits for SKALE chain usage.
- **Configurable pricing and tokens:** Maintains per-token pricing and a list of accepted payment tokens.
- **Access-controlled operations:** Uses `CreditStationAccessManager` for role-based admin and agent permissions.
- **Event-driven fulfillment:** Emits `PaymentReceived` events consumed by `credit-distributor` to fulfill credit purchases on schains.

Credit station project is part of the [SKALE-expand](https://blog.skale.space/blog/skale-expand-bringing-gas-free-instant-private-execution-to-any-evm-blockchain) vision of SKALE. With the new pricing model, developers can buy credits using their preferred token on the chain where skale-manager is deployed, and use them on SKALE-chains to pay-per-usage on network hubs, instead of having to buy their own chain and paying the monthly rate.

Details about the repository structure can be found in [ARCHITECTURE](./docs/ARCHITECTURE.md).

## Installation & Setup

### Prerequisites

- Node.js 22-24 (tested with modern LTS versions)
- Yarn 4 (enabled via `yarn@4.x.x"` in `package.json`)
- Docker (optional - for running the `credit-distributor` service via `docker compose`)
- Python 3.13+ with [uv](https://docs.astral.sh/uv/) for local `credit-distributor` development
- `slither-analyzer` (installed globally or in a suitable Python environment)

### Clone and Install

```bash
git clone --recurse-submodules https://github.com/skalenetwork/credit-station.git
cd credit-station
yarn install
yarn cleanCompile
pip3 install slither-analyzer   # might require the creation of a suitable Python environment
```


## Running Tests

Tests are written in TypeScript and Solidity and run using Hardhat’s local
in-memory network. No external nodes or extra setup are required.

**All tests**

```bash
yarn test
```

This runs TypeScript type-checking (via `yarn tsc`) and the full Hardhat test
suite in `test/`.

**Single test / suite**

```bash
yarn hardhat test test/CreditStation.ts
```

You can point Hardhat to any individual file or pattern under the `test/`
directory.

**Coverage**

```bash
yarn hardhat coverage
```

> Note: coverage requires the `solidity-coverage` plugin, which is already
> listed as a dev dependency.


## Deployment

Deployment is performed using Hardhat scripts in the `migrations/` folder.
All scripts use the `custom` network defined in `hardhat.config.ts`, which
reads RPC and account details from environment variables.

### Common environment

Create a `.env` file at the repository root with:

```dotenv
ENDPOINT="https://your-endpoint"       # RPC endpoint for the target network (mainnet or schain)
PRIVATE_KEY="0x..."                    # Deployer private key with funds on the target network
ETHERSCAN="your-etherscan-api-key"     # Optional: used for contract verification
```

> The `ENDPOINT` and `PRIVATE_KEY` variables are consumed by the `custom`
> network configuration in `hardhat.config.ts`. The `ETHERSCAN` key is used
> by `@nomicfoundation/hardhat-verify` via `@skalenetwork/upgrade-tools`.

### Mainnet deployment (CreditStation)

Mainnet deployment creates:

- `CreditStationAccessManager` – access control for admin/agent roles
- `CreditStation` – mainnet payment entry point

Optional environment variables to control roles:

```dotenv
OWNER="0x..."      # Address that will receive ADMIN_ROLE on AccessManager (defaults to deployer)
RECEIVER="0x..."   # Address that will receive payment tokens (defaults to deployer)
```

Run the mainnet deploy script:

```bash
yarn hardhat run migrations/deployMainnet.ts --network custom
```

This will:

1. Deploy `CreditStationAccessManager` and `CreditStation`.
2. Store deployed addresses in `data/credit-station-mainnet-contracts.json`.
3. Transfer admin permissions from the deployer to `OWNER` (if explicitly set).
4. Try to verify both contracts.

### SKALE chain deployment (Ledger)

Schain deployment creates:

- `CreditStationAccessManager` – access control on the schain
- `Ledger` – contract that fulfills payments on the schain side

Environment variables:

```dotenv
ENDPOINT="https://your-schain-endpoint"   # RPC endpoint for the schain
PRIVATE_KEY="0x..."                        # Deployer key on the schain
OWNER="0x..."                              # (optional) target admin address; defaults to deployer
ETHERSCAN="your-etherscan-api-key"        # Optional, for verification (if supported)
```

Run the schain deploy script:

```bash
yarn hardhat run migrations/deploySchain.ts --network custom
```

This will:

1. Deploy `CreditStationAccessManager` and `Ledger`.
2. Store deployed addresses in `data/credit-station-schain-contracts.json`.
3. Transfer admin permissions from the deployer to `OWNER` (if explicitly set).
4. Try to verify both contracts.

### Official Deployments

Official mainnet and testnet deployment addresses will be documented here.


## Security and Audits

**Static Analysis**

This project uses a combination of Solidity and TypeScript linters and static
analysis tools:

- `solhint` for Solidity style and best practices
- `slither` for advanced Solidity static analysis
- `eslint` for TypeScript/JavaScript
- `cspell` for spellchecking

Run all lint and types checks with:

```bash
yarn fullCheck
```

Run each tool individually:

```bash
yarn lint          # solhint on contracts
yarn eslint        # ESLint on TS/JS files
yarn cspell        # spellcheck
yarn slither       # Slither (requires Slither installed in your python environment)
```

### Bug Bounty Programs

Please see [HackerOne](https://hackerone.com/skale_network?type=team) for SKALE’s
active bug bounty program **or** submit a bug directly via
[encrypted email](https://skale.space/security).


## Main Branches

- **develop** – Most up-to-date branch with the latest features and ongoing work.
  This is where contributions should be opened.
- **stable** – Latest stable version of the project.


## Resources

- **SKALE Whitepaper** – https://skale.space/whitepaper
- **SKALE Developer Documentation** – https://docs.skale.space/
- **SKALE Main Website** – https://www.skale.space/
- **SKALE-BASE Ecosystem Portal** – https://base.skalenodes.com/
- **SKALE Expand** – https://blog.skale.space/blog/skale-expand-bringing-gas-free-instant-private-execution-to-any-evm-blockchain


## License

[![License](https://img.shields.io/github/license/skalenetwork/credit-station.svg)](LICENSE)

Copyright (C) 2025–present SKALE Labs
