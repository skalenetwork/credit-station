import { cleanMainnetDeployment } from "./tools/fixtures.js";
import { network } from "hardhat";
import { should } from "chai";

const { ethers } = await network.connect();
should();

describe("CreditStation", () => {

    it("should set price", async () => {
        const { creditStation, token } = await cleanMainnetDeployment();
        const newPrice = ethers.parseEther("1");
        await creditStation.setPrice(token, newPrice);
        (await creditStation.getPrice(token))
            .should.be.equal(newPrice);
    });
});
