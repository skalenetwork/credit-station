#!/usr/bin/env bash

set -e

yarn hardhat run migrations/deployMainnet.ts
yarn hardhat run migrations/deploySchain.ts
