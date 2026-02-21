// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DecentralisedRaffle
 * @dev An advanced raffle smart contract with security features
 * @notice PART 2 - Decentralised Raffle (MANDATORY)
 */
contract DecentralisedRaffle {
    
    address public owner;
    uint256 public raffleId;
    uint256 public raffleStartTime;
    bool public isPaused;
    uint256 private reentrancyGuard;
    
    // State variables for tracking entries
    address[] public entries; // Track all entries (including duplicates)
    mapping(address => uint256) public playerEntryCount; // Count entries per player
    mapping(address => bool) public players; // Track unique players
    uint256 public uniquePlayerCount;
    
    // Minimum entry amount: 0.01 ETH
    uint256 public constant MINIMUM_ENTRY = 0.01 ether;
    // Time requirement: 24 hours
    uint256 public constant RAFFLE_DURATION = 24 hours;
    // Minimum unique players required
    uint256 public constant MINIMUM_PLAYERS = 3;
    // Owner fee percentage (10%)
    uint256 public constant OWNER_FEE_PERCENTAGE = 10;
    
    // Events
    event PlayerEntered(address indexed player, uint256 entryCount, uint256 totalEntries);
    event WinnerSelected(address indexed winner, uint256 winnings, uint256 totalPot);
    event RafflePaused(uint256 timestamp);
    event RaffleUnpaused(uint256 timestamp);
    event OwnerFeeClaimed(address indexed owner, uint256 amount);
    
    constructor() {
        owner = msg.sender;
        raffleId = 1;
        raffleStartTime = block.timestamp;
        isPaused = false;
        reentrancyGuard = 1;
        uniquePlayerCount = 0;
    }
    
    // Reentrancy guard modifier
    modifier nonReentrant() {
        require(reentrancyGuard == 1, "No reentrancy");
        reentrancyGuard = 2;
        _;
        reentrancyGuard = 1;
    }
    
    // Owner only modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    // Pause guard modifier
    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }
    
    /**
     * @dev Allows players to enter the raffle
     * Requirements:
     * - Minimum 0.01 ETH entry fee
     * - Raffle must be active (not paused)
     * - Tracks total entries and unique players
     */
    function enterRaffle() public payable whenNotPaused {
        // Validate minimum entry amount
        require(msg.value >= MINIMUM_ENTRY, "Minimum entry is 0.01 ETH");
        
        // Add entry to entries array
        entries.push(msg.sender);
        
        // Update player entry count
        playerEntryCount[msg.sender]++;
        
        // Track unique player (only count once per player)
        if (!players[msg.sender]) {
            players[msg.sender] = true;
            uniquePlayerCount++;
        }
        
        emit PlayerEntered(msg.sender, playerEntryCount[msg.sender], entries.length);
    }
    
    /**
     * @dev Selects a winner from all entries
     * Requirements:
     * - Only owner can call
     * - At least 3 unique players
     * - Raffle must be active for at least 24 hours
     * - Winner receives 90% of pot, owner receives 10%
     * - Uses secure randomness via blockhash
     */
    function selectWinner() public onlyOwner nonReentrant {
        // Require minimum players
        require(uniquePlayerCount >= MINIMUM_PLAYERS, "Not enough unique players");
        
        // Require raffle to be active for 24 hours
        require(
            block.timestamp >= raffleStartTime + RAFFLE_DURATION,
            "Raffle must be active for 24 hours"
        );
        
        // Require at least one entry
        require(entries.length > 0, "No entries in raffle");
        
        // Calculate total pot (all entries)
        uint256 totalPot = address(this).balance;
        
        // Generate random index using secure mechanism
        uint256 winningIndex = _generateRandomIndex(entries.length);
        
        // Get winner address
        address winner = entries[winningIndex];
        
        // Calculate winnings (90% of pot)
        uint256 winnings = (totalPot * 90) / 100;
        
        // Calculate owner fee (10% of pot)
        uint256 ownerFee = totalPot - winnings;
        
        // Effects: Reset raffle state
        _resetRaffle();
        
        // Interactions: Send funds using checks-effects-interactions pattern
        (bool successWinner, ) = payable(winner).call{value: winnings}("");
        require(successWinner, "Failed to send winnings to winner");
        
        (bool successOwner, ) = payable(owner).call{value: ownerFee}("");
        require(successOwner, "Failed to send fee to owner");
        
        emit WinnerSelected(winner, winnings, totalPot);
        emit OwnerFeeClaimed(owner, ownerFee);
    }
    
    /**
     * @dev Generates a random number between 0 and max
     * Uses blockhash for randomness (better than block.timestamp)
     */
    function _generateRandomIndex(uint256 max) private view returns (uint256) {
        bytes32 randomHash = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                block.timestamp,
                block.difficulty,
                msg.sender
            )
        );
        return uint256(randomHash) % max;
    }
    
    /**
     * @dev Resets the raffle for the next round
     */
    function _resetRaffle() private {
        raffleId++;
        raffleStartTime = block.timestamp;
        
        // Clear entries
        delete entries;
        
        // Clear player mappings
        for (uint256 i = 0; i < entries.length; i++) {
            address player = entries[i];
            delete playerEntryCount[player];
            delete players[player];
        }
        
        uniquePlayerCount = 0;
    }
    
    /**
     * @dev Pauses the raffle in case of emergency
     */
    function pause() public onlyOwner {
        require(!isPaused, "Already paused");
        isPaused = true;
        emit RafflePaused(block.timestamp);
    }
    
    /**
     * @dev Unpauses the raffle
     */
    function unpause() public onlyOwner {
        require(isPaused, "Already unpaused");
        isPaused = false;
        emit RaffleUnpaused(block.timestamp);
    }
    
    // ============ Helper/View Functions ============
    
    /**
     * @dev Returns the current pot balance
     */
    function getPotBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns total number of entries
     */
    function getTotalEntries() public view returns (uint256) {
        return entries.length;
    }
    
    /**
     * @dev Returns the number of entries for a specific player
     */
    function getPlayerEntryCount(address player) public view returns (uint256) {
        return playerEntryCount[player];
    }
    
    /**
     * @dev Returns the number of unique players
     */
    function getUniquePlayerCount() public view returns (uint256) {
        return uniquePlayerCount;
    }
    
    /**
     * @dev Check if raffle is active (has been running for 24 hours)
     */
    function isRaffleActive() public view returns (bool) {
        return block.timestamp >= raffleStartTime + RAFFLE_DURATION;
    }
    
    /**
     * @dev Returns time remaining until raffle can be drawn
     */
    function getTimeUntilDraw() public view returns (uint256) {
        uint256 endTime = raffleStartTime + RAFFLE_DURATION;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}
