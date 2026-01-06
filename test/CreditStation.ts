import { cleanMainnetDeployment, mainnetWithAllowedToken } from "./tools/fixtures";
import { ethers } from "hardhat";
import { expect, should } from "chai";

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

    it("should get correct payment info", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const price = await creditStation.getPrice(token);
        const schain = "d2-chain";
        const schainHash = await creditStation.toSchainHash(schain);
        await token.mint(user, price * 2n);
        await token.connect(user).approve(creditStation, price * 2n);
        const buyTransaction = await creditStation.connect(user).buy(schain, user, token);
        await buyTransaction.should.changeTokenBalance(
                token,
                await creditStation.receiver(),
                price);
        await buyTransaction
            .should.emit(creditStation, "PaymentReceived")
            .withArgs(1n, schainHash, user, user, token);
        const paymentId = 1n;
        const paymentInfo = await creditStation.getPaymentInfo(paymentId);
        paymentInfo.schainHash.should.be.equal(schainHash);
        paymentInfo.from.should.be.equal(user.address);

        let lastPaymentId = await creditStation.getLastPayment(user.address);
        lastPaymentId.should.be.equal(paymentId);

        await creditStation.connect(user).buy(schain, user, token);

        lastPaymentId = await creditStation.getLastPayment(user.address);
        lastPaymentId.should.be.equal(paymentId + 1n);

        expect(await creditStation.getPaymentIds(user.address, 0n, 2n)).to.deep.equal([1n, 2n]);
        expect(await creditStation.getPaymentIds(user.address, 0n, 20_000n)).to.deep.equal([1n, 2n]);
        expect(await creditStation.getPaymentIds(user.address, 2n, 20_000n)).to.deep.equal([]);

        await creditStation.getPaymentIds(user.address, 3n, 2n).should.be.revertedWithCustomError(
            creditStation,
            "InvalidIndices"
        );

        await creditStation.getPaymentIds(user.address, 2n, 2n).should.be.revertedWithCustomError(
            creditStation,
            "InvalidIndices"
        );

    });

    it("should revert when getting non-existing payment info", async () => {
        const { creditStation } = await mainnetWithAllowedToken();
        const nonExistingPaymentId = 9999n;
        await creditStation.getPaymentInfo(nonExistingPaymentId)
            .should.be.revertedWithCustomError(
                creditStation,
                "PaymentIdDoesNotExist"
            )
            .withArgs(nonExistingPaymentId);
    });
});
