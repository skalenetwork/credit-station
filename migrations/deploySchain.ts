import { ethers } from "hardhat";
import { deployAccessManager, deployLedger, failureCode, storeAddresses, successCode, transferOwnership } from "./deploy";
import chalk from "chalk";
import { AddressLike } from "ethers";
import { getVersion, verify } from "@skalenetwork/upgrade-tools";


const OWNER_PARAMETER = "OWNER";

export const deploySchain = async (owner: AddressLike, version: string) => {
    const accessManager = await deployAccessManager(owner);
    const ledger = await deployLedger(accessManager, version);
    return {
        accessManager,
        ledger
    }
}

const main = async () => {
    const [deployer] = await ethers.getSigners();
    const owner = process.env[OWNER_PARAMETER] || await ethers.resolveAddress(deployer);

    if (process.env[OWNER_PARAMETER]) {
        console.log(chalk.gray(`OWNER is set to ${owner}`));
    } else {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }

    const { accessManager, ledger } = await deploySchain(deployer, await getVersion());

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "Ledger"],
        [accessManager, ledger],
        "mainnet"
    );

    if (await ethers.resolveAddress(deployer) !== await ethers.resolveAddress(owner)) {
        console.log("Setup permissions");
        await transferOwnership(accessManager, deployer, owner);
    }

    console.log("Verify");
    const coder = ethers.AbiCoder.defaultAbiCoder();
    await verify(
        "CreditStationAccessManager",
        accessManager,
        coder.encode(
            ["address"], [await ethers.resolveAddress(owner)]
        ).slice(2));

    await verify(
        "Ledger",
        ledger,
        coder.encode(
            ["address"],
            [await ethers.resolveAddress(accessManager)]
        ).slice(2));

    console.log("Done");
}

if (require.main === module) {
    main()
        .then(() => process.exit(successCode))
        .catch(error => {
            console.error(error);
            process.exit(failureCode);
        });
}
