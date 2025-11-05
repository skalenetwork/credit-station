import { network } from "hardhat";
import { deployAccessManager, deployCreditStation, failureCode, storeAddresses, successCode } from "./deploy.js";
import chalk from "chalk";
import { AddressLike } from "ethers";
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const { ethers } = await network.connect();

const OWNER_PARAMETER = "OWNER";
const RECEIVER_PARAMETER = "RECEIVER";

export const deployMainnet = async (owner: AddressLike, receiver: AddressLike) => {
    const accessManager = await deployAccessManager(owner);
    const creditStation = await deployCreditStation(accessManager, receiver);
    return {
        accessManager,
        creditStation
    }
}

const main = async () => {
    const [deployer] = await ethers.getSigners();
    const owner = process.env[OWNER_PARAMETER] || await ethers.resolveAddress(deployer);
    const receiver = process.env[RECEIVER_PARAMETER] || await ethers.resolveAddress(deployer);

    if (!process.env[OWNER_PARAMETER]) {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }
    if (!process.env[RECEIVER_PARAMETER]) {
        console.log(chalk.yellow(`RECEIVER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${receiver}`));
    }

    const { accessManager, creditStation } = await deployMainnet(owner, receiver);

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "CreditStation"],
        [accessManager, creditStation],
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
