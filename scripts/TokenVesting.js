const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("TokenVesting", function () {
    let TokenVesting;
    let TestToken;
    let tokenVesting;
    let testToken;
    let owner;
    let beneficiary;
    let addr2;

    beforeEach(async function () {
        [owner, beneficiary, addr2] = await ethers.getSigners();

        // Deploy test token
        TestToken = await ethers.getContractFactory("TestToken");
        testToken = await TestToken.deploy();

        // Deploy vesting contract
        TokenVesting = await ethers.getContractFactory("TokenVesting");
        tokenVesting = await TokenVesting.deploy(await testToken.getAddress());

        // Transfer tokens to vesting contract
        await testToken.transfer(await tokenVesting.getAddress(), ethers.parseEther("1000"));
    });

    describe("Vesting Schedule Creation", function () {
        it("Should create a vesting schedule", async function () {
            const now = await time.latest();
            const oneMonth = 30 * 24 * 60 * 60;
            const sixMonths = 6 * oneMonth;

            await tokenVesting.createVestingSchedule(
                beneficiary.address,
                now,
                oneMonth, // 1 month cliff
                sixMonths, // 6 months duration
                ethers.parseEther("100"),
                true
            );

            const scheduleId = await tokenVesting.computeVestingScheduleId(
                beneficiary.address,
                now
            );
            const schedule = await tokenVesting.getVestingSchedule(scheduleId);

            expect(schedule.initialized).to.be.true;
            expect(schedule.beneficiary).to.equal(beneficiary.address);
            expect(schedule.totalAmount).to.equal(ethers.parseEther("100"));
        });
    });

    describe("Token Release", function () {
        it("Should release tokens after cliff", async function () {
            const now = await time.latest();
            const oneMonth = 30 * 24 * 60 * 60;
            const sixMonths = 6 * oneMonth;

            await tokenVesting.createVestingSchedule(
                beneficiary.address,
                now,
                oneMonth,
                sixMonths,
                ethers.parseEther("100"),
                true
            );

            const scheduleId = await tokenVesting.computeVestingScheduleId(
                beneficiary.address,
                now
            );

            // Move time past cliff
            await time.increase(oneMonth + 1);

            // Release tokens
            await tokenVesting.connect(beneficiary).release(scheduleId);

            // Check released amount
            const schedule = await tokenVesting.getVestingSchedule(scheduleId);
            expect(schedule.releasedAmount).to.be.gt(0);
        });
    });

    describe("Revocation", function () {
        it("Should revoke vesting schedule", async function () {
            const now = await time.latest();
            const oneMonth = 30 * 24 * 60 * 60;
            const sixMonths = 6 * oneMonth;

            await tokenVesting.createVestingSchedule(
                beneficiary.address,
                now,
                oneMonth,
                sixMonths,
                ethers.parseEther("100"),
                true
            );

            const scheduleId = await tokenVesting.computeVestingScheduleId(
                beneficiary.address,
                now
            );

            await time.increase(oneMonth + 1);
            await tokenVesting.revoke(scheduleId);

            const schedule = await tokenVesting.getVestingSchedule(scheduleId);
            expect(schedule.revoked).to.be.true;
        });
    });
});