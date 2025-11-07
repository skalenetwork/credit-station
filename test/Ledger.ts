import { schainWithAgent } from "./tools/fixtures.js";
import { ethers } from "hardhat";
import { should } from "chai";

should();

describe("Ledger", () => {
    it("should fulfill order", async () => {
        const [,agent, user] = await ethers.getSigners();
        const paymentId = 1n;
        const value = ethers.parseEther("1");
        const { ledger } = await schainWithAgent();
        (await ledger.isFulfilled(paymentId)).should.be.equal(false);
        await (await ledger.connect(agent).fulfill(paymentId, user, {value}))
            .should.changeEtherBalance(user, value);
        (await ledger.isFulfilled(paymentId)).should.be.equal(true);
    });
});
