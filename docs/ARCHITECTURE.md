# Repository Architecture

This document describes the high-level structure of the `credit-station` repository
and the purpose of its main directories.

## Top-level layout

- `/artifacts`
  Hardhat build output: compiled contract artifacts, ABIs, and build-info. Generated
  automatically by Hardhat and not meant for manual editing.

- `/cache`
  Hardhat and Solidity compiler cache files. Speeds up incremental compilations.

- `/contracts`
  Solidity source code for on-chain components:
  - `CreditStation.sol` – mainnet payment entry point for SKALE credits.
  - `CreditStationAccessManager.sol` – access control for admin and agent roles.
  - `Ledger.sol` – SKALE chain contract that records and fulfills credit payments.
  - `interfaces/` – shared interfaces, custom errors, and type definitions.
  - `test/` – Solidity test contracts used by Hardhat tests.

- `/credit-distributor`
  Python service that listens for `PaymentReceived` events on the mainnet
  `CreditStation` contract and fulfills corresponding payments on a SKALE
  chain `Ledger` contract. Contains its own Docker and Python tooling:
  - `Dockerfile`, `docker-compose.yml` – containerized deployment of the agent.
  - `pyproject.toml` – Python project configuration and dependencies.
  - `src/` – service implementation (configs, state, main loop).

- `/data`
  JSON files with deployed contract addresses and related metadata, written by
  migration scripts (for example, `credit-station-mainnet-contracts.json`).

- `/dictionary`
  Custom dictionary (submodule) files used by `cspell` for spellchecking domain-specific
  terms in this repository.

- `/docs`
  Project documentation, including this architecture overview and any future
  design or protocol notes.

- `/migrations`
  Hardhat deployment scripts used to deploy and verify contracts on mainnet and
  SKALE chains:
  - `deploy.ts` – shared helpers for deploying contracts and storing addresses.
  - `deployMainnet.ts` – orchestrates mainnet deployments (`CreditStation`,
    `CreditStationAccessManager`).
  - `deploySchain.ts` – orchestrates SKALE chain deployments (`Ledger`,
    `CreditStationAccessManager`).

- `/scripts`
  Utility scripts used during development and CI.

- `/test`
  TypeScript test suites and helpers executed via Hardhat:
  - `CreditStation.ts`, `Ledger.ts` – main contract test suites.
  - `tools/` – shared test utilities and fixtures.

- `/typechain-types`
  Auto-generated TypeScript typings and factories produced by TypeChain for
  the Solidity contracts. Used by tests, scripts, and deployment tooling.

- `/.github`
  GitHub configuration such as CI workflows, and other configs.

- `/.githooks`
  Local Git hooks (e.g., pre-commit) configured via the `yarn hooks` script to
  enforce checks before changes are committed.

- `/.yarn` and `yarn.lock`
  Yarn 4 configuration and plug-ins, plus the lockfile that records the exact
  dependency tree for reproducible installs.

- `node_modules`
  Installed JavaScript/TypeScript dependencies. Managed by Yarn; not edited
  directly.

- Project configuration files
  Root-level configs for tooling and analysis:
  - `hardhat.config.ts` – Hardhat network and compiler configuration.
  - `tsconfig.json` – TypeScript compiler options.
  - `eslint.config.mjs` – ESLint rules.
  - `slither.config.json` – Slither static analysis settings.
  - `cspell.json` – configuration for code spellchecking.
  - `.solhint.json` – configuration for the Solidity linter.

