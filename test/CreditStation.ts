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
        const value = 1n;
        await token.mint(user, price * value);
        await token.connect(user).approve(creditStation, price * value);
        const buyTransaction = await creditStation.connect(user).buy(schain, user, token, value);
        await buyTransaction.should.changeTokenBalance(
                token,
                await creditStation.receiver(),
                price * value);
        await buyTransaction
            .should.emit(creditStation, "PaymentReceived")
            .withArgs(1n, schainHash, user, user, token, value);
    });

    it("should allow to pay for multiple credits", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const price = await creditStation.getPrice(token);
        const schain = "d2-chain";
        const schainHash = await creditStation.toSchainHash(schain);
        const value = 3n;
        const totalCost = price * value;
        await token.mint(user, totalCost);
        await token.connect(user).approve(creditStation, totalCost);
        const buyTransaction = await creditStation.connect(user).buy(schain, user, token, value);
        await buyTransaction.should.changeTokenBalance(
                token,
                await creditStation.receiver(),
                totalCost);
        await buyTransaction
            .should.emit(creditStation, "PaymentReceived")
            .withArgs(1n, schainHash, user, user, token, value);
        const paymentInfo = await creditStation.getPaymentInfo(1n);
        paymentInfo.value.should.be.equal(value);
    });

    it("should reject zero value purchase", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const schain = "d2-chain";
        await creditStation.connect(user).buy(schain, user, token, 0n)
            .should.be.revertedWithCustomError(
                creditStation,
                "ValueIsZero"
            );
    });

    it("should get correct payment info", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const price = await creditStation.getPrice(token);
        const schain = "d2-chain";
        const schainHash = await creditStation.toSchainHash(schain);
        const value = 1n;
        await token.mint(user, price * value * 2n);
        await token.connect(user).approve(creditStation, price * value * 2n);
        expect(await creditStation.getPaymentIds(user.address, 0n, 2n**256n - 1n)).to.deep.equal([]);

        const buyTransaction = await creditStation.connect(user).buy(schain, user, token, value);
        await buyTransaction.should.changeTokenBalance(
                token,
                await creditStation.receiver(),
                price * value);
        await buyTransaction
            .should.emit(creditStation, "PaymentReceived")
            .withArgs(1n, schainHash, user, user, token, value);
        const paymentId = 1n;
        const paymentInfo = await creditStation.getPaymentInfo(paymentId);
        paymentInfo.schainHash.should.be.equal(schainHash);
        paymentInfo.from.should.be.equal(user.address);

        let lastPaymentId = await creditStation.getLastPayment(user.address);
        lastPaymentId.should.be.equal(paymentId);

        await creditStation.connect(user).buy(schain, user, token, value);

        lastPaymentId = await creditStation.getLastPayment(user.address);
        lastPaymentId.should.be.equal(paymentId + 1n);

        expect(await creditStation.getPaymentIds(user.address, 0n, 2n)).to.deep.equal([1n, 2n]);
        expect(await creditStation.getPaymentIds(user.address, 0n, 20_000n)).to.deep.equal([1n, 2n]);
        expect(await creditStation.getPaymentIds(user.address, 2n, 20_000n)).to.deep.equal([]);
        expect(await creditStation.getNumberOfPayments(user.address)).to.deep.equal(2n);

        await creditStation.getPaymentIds(user.address, 3n, 2n).should.be.revertedWithCustomError(
            creditStation,
            "InvalidIndices"
        );

        await creditStation.getPaymentIds(user.address, 2n, 2n).should.be.revertedWithCustomError(
            creditStation,
            "InvalidIndices"
        );

        await creditStation.getLastPaymentId().should.eventually.be.equal(2n);
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

    it("should set payment ID offset", async () => {
        const [,,user] = await ethers.getSigners();
        const { creditStation, token } = await mainnetWithAllowedToken();
        const price = await creditStation.getPrice(token);
        const schain = "d2-chain";
        const value = 1n;
        const sourceId = 1n;
        const idOffset = 1000n;
        const expectedFirstId = (sourceId << 248n) | idOffset;

        await creditStation.setPaymentIdOffset(sourceId, idOffset);

        await token.mint(user, price * value);
        await token.connect(user).approve(creditStation, price * value);
        await creditStation.connect(user).buy(schain, user, token, value);

        const lastPaymentId = await creditStation.getLastPaymentId();
        lastPaymentId.should.be.equal(expectedFirstId);

        const paymentInfo = await creditStation.getPaymentInfo(expectedFirstId);
        paymentInfo.from.should.be.equal(user.address);
        paymentInfo.value.should.be.equal(value);
    });

    it("should emit PaymentIdOffsetSet event", async () => {
        const { creditStation } = await mainnetWithAllowedToken();
        const sourceId = 2n;
        const idOffset = 500n;

        await creditStation.setPaymentIdOffset(sourceId, idOffset)
            .should.emit(creditStation, "PaymentIdOffsetSet")
            .withArgs(sourceId, idOffset);
    });
});
