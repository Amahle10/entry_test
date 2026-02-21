# Part B: Test Scenarios Guide

**Complete test scenarios for BOTH contracts.**

---

## Test Scenario 1: FreelanceBountyBoard
**Target:** `FreelanceBountyBoard.sol`

### 1.1 Happy Path
**Description**: Test successful bounty posting and payment.
- **Steps**: ...
- **Expected Result**: ...

### 1.2 Security/Edge Case
**Description**: Attempt reentrancy or unauthorized access.
- **Steps**: ...
- **Expected Result**: ...

---

## Test Scenario 2: DecentralisedRaffle
**Target:** `DecentralisedRaffle.sol`

### 2.1 Happy Path
**Description**: Test entry and winner selection.
- **Steps**: ...
- **Expected Result**: ...

### 2.2 Security/Edge Case
**Description**: Test randomness manipulation or insufficient funds.
- **Steps**: ...
- **Expected Result**: ...

---

## Coverage Assessment
After implementing your tests in `test/`, assess your coverage:
1. **Link to test files:** (e.g., `test/FreelanceBountyBoard.test.js`)
2. **Key functions tested:**
3. **Estimated Coverage:** (Aim for 80%+)

> [!TIP]
> Use `npx hardhat coverage` if you have the plugin installed, otherwise manually verify all state transitions are tested.
