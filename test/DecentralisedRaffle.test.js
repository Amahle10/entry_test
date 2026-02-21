const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentralisedRaffle", function () {
    let raffle;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        
        const Raffle = await ethers.getContractFactory("DecentralisedRaffle");
        raffle = await Raffle.deploy();
        await raffle.deployed();
    });

    describe("Deployment", function () {
        it("Should deploy successfully", async function () {
            expect(raffle.address).to.not.equal(0);
        });
    });

    describe("Raffle Participation", function () {
        it("Should allow users to enter raffle", async function () {
            await raffle.connect(addr1).enter({ value: ethers.utils.parseEther("1") });
            expect(await raffle.getParticipants()).to.include(addr1.address);
        });

        it("Should revert if entry fee is insufficient", async function () {
            await expect(
                raffle.connect(addr1).enter({ value: ethers.utils.parseEther("0.5") })
            ).to.be.revertedWith("Insufficient entry fee");
        });
    });

    describe("Winner Selection", function () {
        it("Should select a winner", async function () {
            await raffle.connect(addr1).enter({ value: ethers.utils.parseEther("1") });
            await raffle.connect(addr2).enter({ value: ethers.utils.parseEther("1") });
            
            await raffle.selectWinner();
            expect(await raffle.winner()).to.not.equal(ethers.constants.AddressZero);
        });
    });
});