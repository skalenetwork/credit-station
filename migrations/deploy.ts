import { AddressLike } from "ethers";
import { ethers } from "hardhat";
import { CreditStation, CreditStationAccessManager, Ledger } from "../typechain-types";
import { promises as fs } from 'fs';
import chalk from "chalk";

export const successCode = 0;
export const failureCode = 1;

export const contracts = [
    "CreditStation",
    "CreditStationAccessManager",
    "Ledger"
] as const;

const deployContract = async<ContractType> (name: typeof contracts[number], args: unknown[]) => {
    console.log(chalk.gray(`Deploying ${name}...`));
    const contract = await ethers.deployContract(name, args);
    await contract.waitForDeployment();
    console.log(`${name}: ${await ethers.resolveAddress(contract)}`);
    return contract as ContractType;

}

export const deployAccessManager = async (
    owner: AddressLike
) => {
    return await deployContract(
        "CreditStationAccessManager",
        [await ethers.resolveAddress(owner)]
    ) as CreditStationAccessManager;
}

export const deployCreditStation = async (
    accessManager: CreditStationAccessManager,
    receiver: AddressLike,
    version: string
) => {
    const creditStation = await deployContract(
        "CreditStation",
        [accessManager, receiver]
    ) as CreditStation;
    const response = await creditStation.setVersion(version);
    await response.wait();
    return creditStation;
}

export const deployLedger = async (
    accessManager: CreditStationAccessManager,
    version: string
) => {
    const ledger = await deployContract(
        "Ledger",
        [accessManager]
    ) as Ledger;

    let response = await accessManager.setTargetFunctionRole(
        await ethers.resolveAddress(ledger),
        [
            ledger.interface.getFunction("fulfill").selector
        ],
        await accessManager.FULFILL_AGENT_ROLE()
    );
    await response.wait();

    response = await ledger.setVersion(version);
    await response.wait();

    return ledger;
}

export const storeAddresses = async (contracts: string[], addresses: AddressLike[], title: string) => {
    const addressesList = new Map<string, string>();
    for (let i = 0; i < contracts.length; i++) {
        const contract = contracts[i];
        const address = await ethers.resolveAddress(addresses[i]);
        addressesList.set(contract, address);
    }
    await fs.writeFile(
        `data/credit-station-${title}-contracts.json`,
        JSON.stringify(Object.fromEntries(addressesList), null, 4));
}
