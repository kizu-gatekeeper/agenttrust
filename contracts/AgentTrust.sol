// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentTrust — On-chain reputation & endorsement board for Agent ID holders
/// @notice Every write is gated by ownership of an Agent ID (ERC-721) issued
///         via the SPACE ID Agent ID registry on BNB Chain.
/// @dev    This contract holds NO user funds. There is no deposit, withdraw,
///         transfer-of-assets, approval, or fee logic anywhere in this file.
///         The owner (deployer) has NO special asset permissions — the only
///         owner-gated action is updating the (display-only) announcement
///         string. Badges are non-transferable records, not tradable tokens.

interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentTrust {
    // ------------------------------------------------------------------
    // Constants / immutables
    // ------------------------------------------------------------------

    /// @notice SPACE ID Agent ID registry on BNB Chain (BSC mainnet, chainId 56)
    IAgentIdRegistry public immutable agentIdRegistry;

    uint8 public constant MAX_CATEGORY = 3; // 0=Builder 1=Trader 2=Creator 3=Helper
    uint256 public constant MAX_WALL_MESSAGE_BYTES = 140;
    uint256 public constant SECONDS_PER_DAY = 86400;

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------

    address public owner;
    string public announcement;

    // Genesis Badge: 1 per wallet, non-transferable record
    mapping(address => bool) public hasBadge;
    mapping(address => uint256) public badgeIdOf; // 0 = none, else 1-based id
    uint256 public totalBadges;

    // Endorsements
    // endorsed[endorser][target][category] = true once given
    mapping(address => mapping(address => mapping(uint8 => bool))) public hasEndorsed;
    mapping(address => uint256) public endorsementCount; // total received
    mapping(address => mapping(uint8 => uint256)) public endorsementCountByCategory;

    // Wall of signatures
    struct WallEntry {
        address author;
        string message;
        uint256 timestamp;
    }
    WallEntry[] private _wall;
    mapping(address => uint256) public lastSignDay; // day index of last signWall
    mapping(address => bool) private _hasSigned;

    // Joined agents (anyone who claimed a badge, endorsed, or signed)
    mapping(address => bool) public joined;
    uint256 public totalJoined;

    // ------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------

    event BadgeClaimed(address indexed agent, uint256 indexed badgeId);
    event Endorsed(address indexed endorser, address indexed target, uint8 indexed category, uint256 newTotalForTarget);
    event WallSigned(address indexed author, uint256 indexed entryIndex, string message);
    event AgentJoined(address indexed agent);
    event AnnouncementUpdated(string announcement);

    // ------------------------------------------------------------------
    // Errors
    // ------------------------------------------------------------------

    error NotAgentIdHolder();
    error TargetNotAgentIdHolder();
    error BadgeAlreadyClaimed();
    error CannotEndorseSelf();
    error InvalidCategory(uint8 category);
    error AlreadyEndorsed();
    error MessageEmpty();
    error MessageTooLong(uint256 length);
    error AlreadySignedToday();
    error NotOwner();
    error ZeroAddress();

    // ------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------

    modifier onlyAgent() {
        if (agentIdRegistry.balanceOf(msg.sender) == 0) revert NotAgentIdHolder();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /// @param registry Address of the Agent ID registry.
    ///        On BSC mainnet: 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
    /// @param initialOwner Project owner (set explicitly because deployment
    ///        goes through a CREATE factory, whose address would otherwise
    ///        become msg.sender in the constructor).
    constructor(address registry, address initialOwner) {
        if (registry == address(0)) revert ZeroAddress();
        if (initialOwner == address(0)) revert ZeroAddress();
        agentIdRegistry = IAgentIdRegistry(registry);
        owner = initialOwner;
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    function _markJoined(address agent) internal {
        if (!joined[agent]) {
            joined[agent] = true;
            totalJoined += 1;
            emit AgentJoined(agent);
        }
    }

    function _isAgent(address who) internal view returns (bool) {
        return agentIdRegistry.balanceOf(who) > 0;
    }

    // ------------------------------------------------------------------
    // Writes (all gated by Agent ID)
    // ------------------------------------------------------------------

    /// @notice Claim your one-time, non-transferable Genesis Badge record.
    function claimBadge() external onlyAgent {
        if (hasBadge[msg.sender]) revert BadgeAlreadyClaimed();
        totalBadges += 1;
        hasBadge[msg.sender] = true;
        badgeIdOf[msg.sender] = totalBadges;
        _markJoined(msg.sender);
        emit BadgeClaimed(msg.sender, totalBadges);
    }

    /// @notice Endorse another Agent ID holder in one category.
    /// @param target   Agent ID holder to endorse (not yourself).
    /// @param category 0=Builder, 1=Trader, 2=Creator, 3=Helper.
    function endorse(address target, uint8 category) external onlyAgent {
        if (target == address(0)) revert ZeroAddress();
        if (target == msg.sender) revert CannotEndorseSelf();
        if (category > MAX_CATEGORY) revert InvalidCategory(category);
        if (!_isAgent(target)) revert TargetNotAgentIdHolder();
        if (hasEndorsed[msg.sender][target][category]) revert AlreadyEndorsed();

        hasEndorsed[msg.sender][target][category] = true;
        endorsementCount[target] += 1;
        endorsementCountByCategory[target][category] += 1;
        _markJoined(msg.sender);
        emit Endorsed(msg.sender, target, category, endorsementCount[target]);
    }

    /// @notice Sign the public wall. One message per wallet per calendar day (UTC day index).
    /// @param message Short message, 1..140 bytes (UTF-8 bytes, not characters).
    function signWall(string calldata message) external onlyAgent {
        bytes memory b = bytes(message);
        if (b.length == 0) revert MessageEmpty();
        if (b.length > MAX_WALL_MESSAGE_BYTES) revert MessageTooLong(b.length);

        uint256 today = block.timestamp / SECONDS_PER_DAY;
        if (_hasSigned[msg.sender] && lastSignDay[msg.sender] == today) {
            revert AlreadySignedToday();
        }
        _hasSigned[msg.sender] = true;
        lastSignDay[msg.sender] = today;

        _wall.push(WallEntry({author: msg.sender, message: message, timestamp: block.timestamp}));
        _markJoined(msg.sender);
        emit WallSigned(msg.sender, _wall.length - 1, message);
    }

    // ------------------------------------------------------------------
    // Owner (display only — NO asset permissions)
    // ------------------------------------------------------------------

    /// @notice Update a short announcement string shown on the frontend.
    /// @dev This is the ONLY owner-gated function. The owner cannot mint
    ///      badges for others, cannot edit endorsements or wall entries,
    ///      cannot pause the contract, and cannot move any assets —
    ///      the contract holds no user funds and has no payable functions.
    function setAnnouncement(string calldata text) external onlyOwner {
        announcement = text;
        emit AnnouncementUpdated(text);
    }

    /// @notice Transfer the display-only ownership role. No asset impact.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        owner = newOwner;
    }

    // ------------------------------------------------------------------
    // Read helpers
    // ------------------------------------------------------------------

    function isAgentIdHolder(address who) external view returns (bool) {
        return _isAgent(who);
    }

    function endorsementCountOf(address who) external view returns (uint256) {
        return endorsementCount[who];
    }

    function endorsementCountOfCategory(address who, uint8 category) external view returns (uint256) {
        if (category > MAX_CATEGORY) revert InvalidCategory(category);
        return endorsementCountByCategory[who][category];
    }

    // hasBadge(address) is auto-generated from the public mapping above.

    function totalAgentsJoined() external view returns (uint256) {
        return totalJoined;
    }

    function wallCount() external view returns (uint256) {
        return _wall.length;
    }

    function getWallEntry(uint256 i) external view returns (address author, string memory message, uint256 timestamp) {
        WallEntry storage e = _wall[i];
        return (e.author, e.message, e.timestamp);
    }

    /// @notice Convenience: fetch the most recent `n` wall entries (newest last).
    function getRecentWallEntries(uint256 n) external view returns (WallEntry[] memory) {
        uint256 len = _wall.length;
        if (n > len) n = len;
        WallEntry[] memory out = new WallEntry[](n);
        for (uint256 i = 0; i < n; i++) {
            out[i] = _wall[len - n + i];
        }
        return out;
    }

    // Explicitly no receive()/fallback payable: this contract must never
    // custody BNB or tokens. Plain BNB transfers to it will revert.
}
