// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title FreelanceBountyBoard
 * @dev A decentralised marketplace for skills and bounties
 * @notice PART 1 - Freelance Bounty Board (MANDATORY)
 */
contract FreelanceBountyBoard {
    
    // ============ Events ============
    event FreelancerRegistered(address indexed freelancer, string skill);
    event BountyPosted(uint256 indexed bountyId, address indexed employer, uint256 reward);
    event BountyApplied(uint256 indexed bountyId, address indexed freelancer);
    event WorkSubmitted(uint256 indexed bountyId, address indexed freelancer, string submissionUrl);
    event WorkApproved(uint256 indexed bountyId, address indexed freelancer, uint256 reward);
    event DisputeInitiated(uint256 indexed bountyId, address indexed initiator);
    
    // ============ Enums ============
    enum BountyStatus { Open, InProgress, Submitted, Completed, Disputed }
    
    // ============ Structs ============
    struct Freelancer {
        bool isRegistered;
        string skill;
        uint256 completedBounties;
        uint256 totalEarnings;
    }
    
    struct Bounty {
        uint256 id;
        address employer;
        string description;
        string skillRequired;
        uint256 reward;
        address selectedFreelancer;
        string submissionUrl;
        BountyStatus status;
        uint256 createdAt;
        uint256 deadline;
    }
    
    // ============ State Variables ============
    address public owner;
    
    // Mapping to track freelancers
    mapping(address => Freelancer) public freelancers;
    
    // Mapping to track bounties
    mapping(uint256 => Bounty) public bounties;
    
    // Mapping to track applications: bountyId => freelancer => hasApplied
    mapping(uint256 => mapping(address => bool)) public applications;
    
    // Counter for bounty IDs
    uint256 public bountyCounter;
    
    // Reentrancy guard
    uint256 private locked;
    
    // ============ Modifiers ============
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier isRegisteredFreelancer() {
        require(freelancers[msg.sender].isRegistered, "Freelancer not registered");
        _;
    }
    
    modifier nonReentrant() {
        require(locked == 0, "No reentrancy");
        locked = 1;
        _;
        locked = 0;
    }
    
    modifier bountyExists(uint256 bountyId) {
        require(bountyId < bountyCounter, "Bounty does not exist");
        _;
    }
    
    // ============ Constructor ============
    constructor() {
        owner = msg.sender;
        bountyCounter = 0;
        locked = 0;
    }
    
    // ============ Freelancer Management ============
    
    /**
     * @dev Register as a freelancer with a specific skill
     * @param skill The skill the freelancer possesses
     * Requirements:
     * - Input validation (non-empty skill)
     * - Prevent duplicate registrations
     */
    function registerFreelancer(string memory skill) public {
        require(bytes(skill).length > 0, "Skill cannot be empty");
        require(!freelancers[msg.sender].isRegistered, "Already registered as freelancer");
        
        freelancers[msg.sender] = Freelancer({
            isRegistered: true,
            skill: skill,
            completedBounties: 0,
            totalEarnings: 0
        });
        
        emit FreelancerRegistered(msg.sender, skill);
    }
    
    /**
     * @dev Get freelancer details
     * @param freelancerAddress Address of the freelancer
     * @return Freelancer struct containing registration status and skills
     */
    function getFreelancerDetails(address freelancerAddress) public view returns (Freelancer memory) {
        return freelancers[freelancerAddress];
    }
    
    // ============ Bounty Workflow ============
    
    /**
     * @dev Post a new bounty
     * @param description Description of the bounty
     * @param skillRequired The required skill for the bounty
     * Requirements:
     * - ETH must be sent with transaction
     * - Description and skill cannot be empty
     */
    function postBounty(string memory description, string memory skillRequired) public payable {
        require(msg.value > 0, "Bounty reward must be greater than 0");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(skillRequired).length > 0, "Skill requirement cannot be empty");
        
        uint256 bountyId = bountyCounter;
        
        bounties[bountyId] = Bounty({
            id: bountyId,
            employer: msg.sender,
            description: description,
            skillRequired: skillRequired,
            reward: msg.value,
            selectedFreelancer: address(0),
            submissionUrl: "",
            status: BountyStatus.Open,
            createdAt: block.timestamp,
            deadline: block.timestamp + 30 days
        });
        
        bountyCounter++;
        
        emit BountyPosted(bountyId, msg.sender, msg.value);
    }
    
    /**
     * @dev Apply for a bounty
     * @param bountyId ID of the bounty to apply for
     * Requirements:
     * - Freelancer must be registered
     * - Freelancer must have required skill
     * - Bounty must be in Open status
     * - Prevent duplicate applications
     */
    function applyForBounty(uint256 bountyId) public isRegisteredFreelancer bountyExists(bountyId) {
        Bounty storage bounty = bounties[bountyId];
        
        require(bounty.status == BountyStatus.Open, "Bounty is not open for applications");
        require(!applications[bountyId][msg.sender], "Already applied for this bounty");
        
        // Check if freelancer has the required skill
        require(
            keccak256(bytes(freelancers[msg.sender].skill)) == keccak256(bytes(bounty.skillRequired)),
            "You do not have the required skill for this bounty"
        );
        
        applications[bountyId][msg.sender] = true;
        bounty.selectedFreelancer = msg.sender;
        bounty.status = BountyStatus.InProgress;
        
        emit BountyApplied(bountyId, msg.sender);
    }
    
    /**
     * @dev Submit completed work for a bounty
     * @param bountyId ID of the bounty
     * @param submissionUrl URL or IPFS hash of the submission
     * Requirements:
     * - Freelancer must be the one who applied
     * - Bounty must be InProgress
     */
    function submitWork(uint256 bountyId, string memory submissionUrl) public bountyExists(bountyId) {
        require(bytes(submissionUrl).length > 0, "Submission URL cannot be empty");
        
        Bounty storage bounty = bounties[bountyId];
        
        require(bounty.status == BountyStatus.InProgress, "Bounty is not in progress");
        require(bounty.selectedFreelancer == msg.sender, "Only the assigned freelancer can submit work");
        
        bounty.submissionUrl = submissionUrl;
        bounty.status = BountyStatus.Submitted;
        
        emit WorkSubmitted(bountyId, msg.sender, submissionUrl);
    }
    
    // ============ Payment & Security ============
    
    /**
     * @dev Employer approves work and pays the freelancer
     * @param bountyId ID of the bounty to approve
     * @param freelancer Address of the freelancer to pay
     * Requirements:
     * - Only employer who posted the bounty can approve
     * - Bounty must be in Submitted status
     * - Uses Checks-Effects-Interactions pattern for reentrancy protection
     */
    function approveAndPay(uint256 bountyId, address freelancer) public nonReentrant bountyExists(bountyId) {
        Bounty storage bounty = bounties[bountyId];
        
        // CHECKS
        require(bounty.employer == msg.sender, "Only bounty employer can approve payment");
        require(bounty.status == BountyStatus.Submitted, "Bounty is not in submitted status");
        require(bounty.selectedFreelancer == freelancer, "Freelancer did not submit work for this bounty");
        
        uint256 reward = bounty.reward;
        
        // EFFECTS - Update state first before external call
        bounty.status = BountyStatus.Completed;
        freelancers[freelancer].completedBounties++;
        freelancers[freelancer].totalEarnings += reward;
        
        emit WorkApproved(bountyId, freelancer, reward);
        
        // INTERACTIONS - External call last
        (bool success, ) = payable(freelancer).call{value: reward}("");
        require(success, "Payment transfer failed");
    }
    
    // ============ Dispute Resolution (BONUS) ============
    
    /**
     * @dev Initiate a dispute for a bounty
     * @param bountyId ID of the bounty in dispute
     * Requirements:
     * - Can be called by employer or freelancer
     * - Bounty must not be completed or already disputed
     */
    function initiateDispute(uint256 bountyId) public bountyExists(bountyId) {
        Bounty storage bounty = bounties[bountyId];
        
        require(
            msg.sender == bounty.employer || msg.sender == bounty.selectedFreelancer,
            "Only employer or assigned freelancer can initiate dispute"
        );
        require(
            bounty.status != BountyStatus.Completed && bounty.status != BountyStatus.Disputed,
            "Cannot dispute completed or already disputed bounties"
        );
        require(block.timestamp <= bounty.deadline + 7 days, "Dispute window has expired");
        
        bounty.status = BountyStatus.Disputed;
        
        emit DisputeInitiated(bountyId, msg.sender);
    }
    
    // ============ Helper Functions ============
    
    /**
     * @dev Get all bounty details
     * @param bountyId ID of the bounty
     * @return Bounty struct with all information
     */
    function getBountyDetails(uint256 bountyId) public view bountyExists(bountyId) returns (Bounty memory) {
        return bounties[bountyId];
    }
    
    /**
     * @dev Get all bounties
     * @return Array of all bounties
     */
    function getAllBounties() public view returns (Bounty[] memory) {
        Bounty[] memory allBounties = new Bounty[](bountyCounter);
        for (uint256 i = 0; i < bountyCounter; i++) {
            allBounties[i] = bounties[i];
        }
        return allBounties;
    }
    
    /**
     * @dev Check if freelancer has applied for a bounty
     * @param bountyId ID of the bounty
     * @param freelancerAddress Address of the freelancer
     * @return Whether freelancer has applied
     */
    function hasApplied(uint256 bountyId, address freelancerAddress) public view returns (bool) {
        return applications[bountyId][freelancerAddress];
    }
    
    /**
     * @dev Get freelancer statistics
     * @param freelancerAddress Address of the freelancer
     * @return completedBounties Number of completed bounties
     * @return totalEarnings Total earnings in wei
     */
    function getFreelancerStats(address freelancerAddress) public view returns (uint256 completedBounties, uint256 totalEarnings) {
        return (freelancers[freelancerAddress].completedBounties, freelancers[freelancerAddress].totalEarnings);
    }
}
