// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PharosSoulbound
 * @author young3pbeats-dev
 * @notice Soulbound Token (ERC721 non-transferable) with fully on-chain SVG metadata,
 *         3-tier reputation levels, and deployer-controlled minting/revocation.
 *         Deployed on Pharos Atlantic Testnet.
 *
 * Architecture:
 *  - Each address can hold at most one SBT (one identity, one badge)
 *  - Tokens are permanently bound to the recipient — transfers are blocked
 *  - SVG image and JSON metadata are generated entirely on-chain (no IPFS)
 *  - Owner can mint, upgrade, or revoke badges at any time
 *  - Three reputation tiers: Builder (1) / Contributor (2) / Legend (3)
 */
contract PharosSoulbound {

    // ─────────────────────────────────────────────
    //  ERRORS
    // ─────────────────────────────────────────────

    error NotOwner();
    error ZeroAddress();
    error AlreadyHoldsSBT();
    error NoSBTFound();
    error SoulboundTransferBlocked();
    error InvalidTier();

    // ─────────────────────────────────────────────
    //  TYPES
    // ─────────────────────────────────────────────

    enum Tier { None, Builder, Contributor, Legend }

    struct Badge {
        uint256 tokenId;
        Tier    tier;
        uint256 issuedAt;
        uint256 updatedAt;
        string  label;
    }

    // ─────────────────────────────────────────────
    //  ERC721 MINIMAL STATE
    // ─────────────────────────────────────────────

    string public name   = "Pharos Soulbound Badge";
    string public symbol = "PSB";

    uint256 private _totalSupply;
    uint256 private _nextTokenId = 1;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;

    // ─────────────────────────────────────────────
    //  SOULBOUND STATE
    // ─────────────────────────────────────────────

    address public owner;

    mapping(address => Badge)   public badges;       // holder => Badge
    mapping(uint256 => address) public holderOf;     // tokenId => holder
    mapping(address => bool)    public hasBadge;

    // ─────────────────────────────────────────────
    //  EVENTS
    // ─────────────────────────────────────────────

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event BadgeMinted(address indexed to, uint256 tokenId, Tier tier, string label, uint256 timestamp);
    event BadgeUpgraded(address indexed holder, uint256 tokenId, Tier oldTier, Tier newTier, uint256 timestamp);
    event BadgeRevoked(address indexed holder, uint256 tokenId, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ─────────────────────────────────────────────
    //  MODIFIERS
    // ─────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ─────────────────────────────────────────────
    //  CONSTRUCTOR
    // ─────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────
    //  OWNER: MINT
    // ─────────────────────────────────────────────

    /**
     * @notice Mint a Soulbound Badge to an address.
     * @param to    Recipient address.
     * @param tier  1 = Builder, 2 = Contributor, 3 = Legend.
     * @param label Custom label stored on-chain (e.g. "Atlantic Pioneer").
     */
    function mint(address to, uint256 tier, string calldata label) external onlyOwner {
        if (to == address(0))  revert ZeroAddress();
        if (hasBadge[to])      revert AlreadyHoldsSBT();
        if (tier < 1 || tier > 3) revert InvalidTier();

        uint256 tokenId = _nextTokenId++;
        _totalSupply++;

        Tier t = Tier(tier);

        badges[to] = Badge({
            tokenId:   tokenId,
            tier:      t,
            issuedAt:  block.timestamp,
            updatedAt: block.timestamp,
            label:     label
        });

        holderOf[tokenId] = to;
        hasBadge[to]      = true;
        _ownerOf[tokenId] = to;
        _balanceOf[to]    = 1;

        emit Transfer(address(0), to, tokenId);
        emit BadgeMinted(to, tokenId, t, label, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  OWNER: UPGRADE TIER
    // ─────────────────────────────────────────────

    /**
     * @notice Upgrade (or downgrade) the tier of an existing badge.
     */
    function upgradeTier(address holder, uint256 newTier) external onlyOwner {
        if (!hasBadge[holder])          revert NoSBTFound();
        if (newTier < 1 || newTier > 3) revert InvalidTier();

        Tier oldTier = badges[holder].tier;
        Tier t       = Tier(newTier);

        badges[holder].tier      = t;
        badges[holder].updatedAt = block.timestamp;

        emit BadgeUpgraded(holder, badges[holder].tokenId, oldTier, t, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  OWNER: REVOKE
    // ─────────────────────────────────────────────

    /**
     * @notice Revoke and burn a badge from a holder.
     */
    function revoke(address holder) external onlyOwner {
        if (!hasBadge[holder]) revert NoSBTFound();

        uint256 tokenId = badges[holder].tokenId;

        delete holderOf[tokenId];
        delete _ownerOf[tokenId];
        delete badges[holder];

        hasBadge[holder]    = false;
        _balanceOf[holder]  = 0;
        _totalSupply--;

        emit Transfer(holder, address(0), tokenId);
        emit BadgeRevoked(holder, tokenId, block.timestamp);
    }

    // ─────────────────────────────────────────────
    //  OWNER: TRANSFER OWNERSHIP
    // ─────────────────────────────────────────────

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ─────────────────────────────────────────────
    //  ERC721: SOULBOUND — TRANSFERS BLOCKED
    // ─────────────────────────────────────────────

    function transferFrom(address, address, uint256) external pure {
        revert SoulboundTransferBlocked();
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert SoulboundTransferBlocked();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert SoulboundTransferBlocked();
    }

    function approve(address, uint256) external pure {
        revert SoulboundTransferBlocked();
    }

    function setApprovalForAll(address, bool) external pure {
        revert SoulboundTransferBlocked();
    }

    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    // ─────────────────────────────────────────────
    //  ERC721: READ
    // ─────────────────────────────────────────────

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert ZeroAddress();
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address holder = _ownerOf[tokenId];
        if (holder == address(0)) revert NoSBTFound();
        return holder;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // ─────────────────────────────────────────────
    //  ERC165 SUPPORT
    // ─────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x01ffc9a7;   // ERC165
    }

    // ─────────────────────────────────────────────
    //  ON-CHAIN METADATA (tokenURI)
    // ─────────────────────────────────────────────

    /**
     * @notice Returns a fully on-chain base64-encoded JSON metadata with embedded SVG.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        address holder = _ownerOf[tokenId];
        if (holder == address(0)) revert NoSBTFound();

        Badge memory b = badges[holder];
        string memory svg      = _buildSVG(b, holder);
        string memory tierName = _tierName(b.tier);

        string memory json = string(abi.encodePacked(
            '{"name":"Pharos Soulbound Badge #', _toString(tokenId), '",',
            '"description":"Soulbound reputation badge issued on Pharos Atlantic Testnet.",',
            '"attributes":[',
                '{"trait_type":"Tier","value":"', tierName, '"},',
                '{"trait_type":"Label","value":"', b.label, '"},',
                '{"trait_type":"Issued At","value":', _toString(b.issuedAt), '},',
                '{"trait_type":"Soulbound","value":"true"}',
            '],',
            '"image":"data:image/svg+xml;base64,', _base64(bytes(svg)), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,", _base64(bytes(json))
        ));
    }

    // ─────────────────────────────────────────────
    //  SVG GENERATION
    // ─────────────────────────────────────────────

    function _buildSVG(Badge memory b, address holder) internal pure returns (string memory) {
        (string memory color1, string memory color2, string memory tierLabel) = _tierColors(b.tier);
        string memory addrShort = _shortAddr(holder);

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">',
            '<defs>',
                '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
                    '<stop offset="0%" style="stop-color:', color1, ';stop-opacity:1"/>',
                    '<stop offset="100%" style="stop-color:', color2, ';stop-opacity:1"/>',
                '</linearGradient>',
            '</defs>',
            '<rect width="320" height="200" rx="16" fill="url(#bg)"/>',
            '<text x="16" y="36" font-family="monospace" font-size="13" fill="white" opacity="0.7">PHAROS ATLANTIC</text>',
            '<text x="16" y="72" font-family="monospace" font-size="22" font-weight="bold" fill="white">', tierLabel, '</text>',
            '<text x="16" y="100" font-family="monospace" font-size="12" fill="white" opacity="0.85">', b.label, '</text>',
            '<text x="16" y="178" font-family="monospace" font-size="10" fill="white" opacity="0.6">', addrShort, '</text>',
            '<text x="304" y="178" font-family="monospace" font-size="10" fill="white" opacity="0.6" text-anchor="end">SOULBOUND</text>',
            '<rect x="16" y="148" width="288" height="1" fill="white" opacity="0.2"/>',
            '</svg>'
        ));
    }

    function _tierColors(Tier t) internal pure returns (string memory, string memory, string memory) {
        if (t == Tier.Legend)      return ("#7B2FF7", "#F107A3", "&#11088; LEGEND");
        if (t == Tier.Contributor) return ("#0F62FE", "#00B4D8", "&#128640; CONTRIBUTOR");
        return ("#1A7F5A", "#22C55E", "&#128296; BUILDER");
    }

    function _tierName(Tier t) internal pure returns (string memory) {
        if (t == Tier.Legend)      return "Legend";
        if (t == Tier.Contributor) return "Contributor";
        return "Builder";
    }

    // ─────────────────────────────────────────────
    //  UTILS
    // ─────────────────────────────────────────────

    function _shortAddr(address a) internal pure returns (string memory) {
        bytes memory b = abi.encodePacked(a);
        bytes memory hex_chars = "0123456789abcdef";
        bytes memory result = new bytes(12); // "0x" + 4 + ".." + 4
        result[0] = '0'; result[1] = 'x';
        for (uint i = 0; i < 4; i++) {
            result[2 + i*2]     = hex_chars[uint8(b[i]) >> 4];
            result[2 + i*2 + 1] = hex_chars[uint8(b[i]) & 0x0f];
        }
        result[10] = '.'; result[11] = '.';
        return string(result);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _base64(bytes memory data) internal pure returns (string memory) {
        bytes memory TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        uint256 i = 0;
        uint256 j = 0;
        while (i < data.length) {
            uint256 a = i < data.length ? uint8(data[i++]) : 0;
            uint256 b = i < data.length ? uint8(data[i++]) : 0;
            uint256 c = i < data.length ? uint8(data[i++]) : 0;
            uint256 triple = (a << 16) | (b << 8) | c;
            result[j++] = TABLE[(triple >> 18) & 0x3F];
            result[j++] = TABLE[(triple >> 12) & 0x3F];
            result[j++] = TABLE[(triple >>  6) & 0x3F];
            result[j++] = TABLE[ triple        & 0x3F];
        }
        // Padding
        if (data.length % 3 == 1) { result[encodedLen - 1] = '='; result[encodedLen - 2] = '='; }
        else if (data.length % 3 == 2) { result[encodedLen - 1] = '='; }
        return string(result);
    }
}
