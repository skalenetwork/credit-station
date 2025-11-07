
import { ethers } from "hardhat";
import { deployMainnet } from "../../migrations/deployMainnet";
import { deploySchain } from "../../migrations/deploySchain";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { Token } from "../../typechain-types";

// Fixtures

const deployMainnetFixture = async () => {
    const [owner, receiver] = await ethers.getSigners();
    const contracts = await deployMainnet(owner, receiver, "test");
    const token = await ethers.deployContract("Token", ["Test Token", "TTK"]) as Token;
    return { ...contracts, token };
}

const deploySchainFixture = async () => {
    const [owner] = await ethers.getSigners();
    const contracts = await deploySchain(owner, "test");
    return contracts;
}

const allowToken = async () => {
    const contracts = await cleanMainnetDeployment();
    const { creditStation, token } = contracts;
    const price = ethers.parseEther("1");
    await creditStation.setPrice(token, price);
    return contracts;
}

const registerAgent = async () => {
    const contracts = await cleanSchainDeployment();
    const { accessManager } = contracts;
    const [, agent] = await ethers.getSigners();
    await accessManager.grantRole(
        await accessManager.FULFILL_AGENT_ROLE(),
        agent,
        0
    );
    return contracts;
}

// External functions

export const cleanMainnetDeployment = async () => loadFixture(deployMainnetFixture);
export const cleanSchainDeployment = async () => loadFixture(deploySchainFixture);
export const mainnetWithAllowedToken = async () => loadFixture(allowToken);
export const schainWithAgent = async () => loadFixture(registerAgent);
