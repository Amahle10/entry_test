describe('FreelanceBountyBoard', () => {
    let freelanceBountyBoard;

    beforeEach(() => {
        // Initialize FreelanceBountyBoard instance
        freelanceBountyBoard = new FreelanceBountyBoard();
    });

    describe('createBounty', () => {
        it('should create a new bounty', () => {
            const bounty = freelanceBountyBoard.createBounty({
                title: 'Fix bug',
                description: 'Critical bug fix needed',
                reward: 100
            });

            expect(bounty).toBeDefined();
            expect(bounty.title).toBe('Fix bug');
        });
    });

    describe('getBounties', () => {
        it('should return all bounties', () => {
            freelanceBountyBoard.createBounty({
                title: 'Task 1',
                description: 'Description',
                reward: 50
            });

            const bounties = freelanceBountyBoard.getBounties();
            expect(bounties.length).toBeGreaterThan(0);
        });
    });

    describe('claimBounty', () => {
        it('should claim a bounty', () => {
            const bounty = freelanceBountyBoard.createBounty({
                title: 'Task',
                description: 'Description',
                reward: 100
            });

            const claimed = freelanceBountyBoard.claimBounty(bounty.id, 'freelancer1');
            expect(claimed.claimedBy).toBe('freelancer1');
        });
    });
});