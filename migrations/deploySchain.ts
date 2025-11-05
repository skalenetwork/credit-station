import { network } from "hardhat";
import { deployAccessManager, deployLedger, failureCode, storeAddresses, successCode } from "./deploy.js";
import chalk from "chalk";
const { ethers } = await network.connect();

const OWNER_PARAMETER = "OWNER";

const main = async () => {
    const [deployer] = await ethers.getSigners();
    const owner = process.env[OWNER_PARAMETER] || await ethers.resolveAddress(deployer);

    if (!process.env[OWNER_PARAMETER]) {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }

    const accessManager = await deployAccessManager(owner);
    const ledger = await deployLedger(accessManager);

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "Ledger"],
        [accessManager, ledger],
        "mainnet"
    );
    console.log("Done");
}

main()
    .then(() => process.exit(successCode))
    .catch(error => {
        console.error(error);
        process.exit(failureCode);
    });
