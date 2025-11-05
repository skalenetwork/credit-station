import { network } from "hardhat";
import { deployAccessManager, deployLedger, failureCode, storeAddresses, successCode } from "./deploy.js";
import chalk from "chalk";
import { AddressLike } from "ethers";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
const { ethers } = await network.connect();

const OWNER_PARAMETER = "OWNER";

export const deploySchain = async (owner: AddressLike) => {
    const accessManager = await deployAccessManager(owner);
    const ledger = await deployLedger(accessManager);
    return {
        accessManager,
        ledger
    }
}

const main = async () => {
    const [deployer] = await ethers.getSigners();
    const owner = process.env[OWNER_PARAMETER] || await ethers.resolveAddress(deployer);

    if (!process.env[OWNER_PARAMETER]) {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }

    const { accessManager, ledger } = await deploySchain(owner);

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "Ledger"],
        [accessManager, ledger],
        "mainnet"
    );
    console.log("Done");
}

const currentFileAbsPath = fileURLToPath(import.meta.url);
const runCommandIndex = process.argv.indexOf('run');
let isRunAsMainScript = false;
if (runCommandIndex !== -1 && process.argv.length > runCommandIndex + 1) {
    const scriptArgAbsPath = resolve(process.argv[runCommandIndex + 1]);
    isRunAsMainScript = (currentFileAbsPath === scriptArgAbsPath);
}
if (isRunAsMainScript) {
    main()
        .then(() => process.exit(successCode))
        .catch(error => {
            console.error(error);
            process.exit(failureCode);
        });
}
