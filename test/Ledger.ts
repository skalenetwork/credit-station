import { schainWithAgent } from "./tools/fixtures.js";
import { network } from "hardhat";
import { should } from "chai";

const { ethers } = await network.connect();
should();

describe("Ledger", () => {
    it("should fulfill order", async () => {
        const [,agent, user] = await ethers.getSigners();
        const paymentId = 1n;
        const value = ethers.parseEther("1");
        const { ledger } = await schainWithAgent();
        (await ledger.isFulfilled(paymentId)).should.be.equal(false);
        await (await ledger.connect(agent).fulfill(paymentId, user, {value}))
            .should.changeEtherBalance(ethers, user, value);
        (await ledger.isFulfilled(paymentId)).should.be.equal(true);
    });
});
