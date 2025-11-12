import { cleanMainnetDeployment, mainnetWithAllowedToken } from "./tools/fixtures";
import { ethers } from "hardhat";
import { should } from "chai";

should();

describe("CreditStation", () => {
    it("should set price", async () => {
        const { creditStation, token } = await cleanMainnetDeployment();
        const newPrice = ethers.parseEther("1");
        await creditStation.setPrice(token, newPrice);
        (await creditStation.getPrice(token))
            .should.be.equal(newPrice);
    });

    it("should allow to pay", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const price = await creditStation.getPrice(token);
        const schain = "d2-chain";
        const schainHash = await creditStation.toSchainHash(schain);
        await token.mint(user, price);
        await token.connect(user).approve(creditStation, price);
        const buyTransaction = await creditStation.connect(user).buy(schain, user, token);
        await buyTransaction.should.changeTokenBalance(
                token,
                await creditStation.receiver(),
                price);
        await buyTransaction
            .should.emit(creditStation, "PaymentReceived")
            .withArgs(1n, schainHash, user, user, token);
    });
});
