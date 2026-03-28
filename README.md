# Pharos Atlantic Contracts

Minimal Solidity contracts deployed on Pharos Atlantic Testnet.

---

## 🔹 CounterLite.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://atlantic.pharosscan.xyz/address/0x5C740823bD4aBBCFA72FC6ca91E9bdBa6Cb03907

---

## 🔹 PharosHello.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://atlantic.pharosscan.xyz/address/0x45ed57D7CE1A0AC29EFb0a4dcBb0c37351efC242

---

## 🔹 SimpleVault.sol ⚙️

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharos-explorer.io/address/0x7103e628a75FcC2F005c0175b5792168D064dE02  
**Type:** ETH Vault / Ownership Control

Minimal ETH vault allowing deposits via receive() and owner-only withdrawals.

---

## 🔹 TimeLockVault.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharos-explorer.io/address/0x5386a04D1daeC4ba3855FB214fAD226287957385  
**Type:** Time-Locked ETH Vault

ETH vault contract that locks deposited funds until a predefined unlock timestamp.
Withdrawals are restricted to the owner and only allowed after the unlock time.

---

## 🔹 ExecutionVault.sol ⚙️

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharoscan.xyz/address/0x183FC87B07Cb3dA65734174415B2FCd8E9939382  
**Type:** ETH Vault / Execution Utility

Minimal ETH vault allowing direct deposits via `receive()` and owner-only withdrawals.  
Implements modern ETH transfer logic using `call`, ownership management, and full event logging.

---

## 🔹 AuthorizedVault.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharosscan.io/address/0xf3ba5BC136356a26b8dddCFA22c2252D7Bc20C81  
**Type:** Permissioned ETH Vault / Allowance-Based Withdrawal

AuthorizedVault is a lightweight ETH vault that allows the owner to assign granular withdrawal permissions to specific addresses. Authorized spenders can withdraw ETH up to a predefined allowance, which is enforced and updated on-chain after each withdrawal.

The contract is designed to demonstrate access control, allowance management, and safe ETH transfers using modern Solidity best practices.

---

## 🔹 EventFlag.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharosscan.io/address/0x158410ad194fc7AFf9A67D7acFf2096F9b5289C1  
**Type:** Event / Flag Registry

Minimal smart contract to store and toggle boolean flags on-chain.

Designed for event signaling, testing workflows, and builder activity tracking.
Only the deployer can set or update flags.

---

## 🔹 PharosBadge.sol

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharosscan.io/address/0x4C4eb8fb2C01AEBD5F0841E6CDbF67AcCaD78541  
**Type:** On-chain Badge / Reputation Registry

PharosBadge is a lightweight on-chain reputation contract that allows the deployer to issue and revoke badges for specific addresses.

Each badge stores a custom label and an issuance timestamp, providing verifiable proof of participation or status.

The contract demonstrates access control, structured state storage, and event-based tracking, and can be used as a foundation for reputation systems, contributor recognition, whitelist logic, or future NFT-based extensions.

---

## 🔹 PharosStakingPool.sol ⚙️

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharosscan.io/address/0x3dd487eB60EE43d53169766eA692Cd2e68038116  
**Type:** Epoch-Based ETH Staking Pool

ETH staking pool with per-block reward accrual, 4-tier multiplier system (1x–2x),

---

## 🔹 PharosSoulbound.sol ⚙️

**Network:** Pharos Atlantic Testnet  
**Address:** https://pharosscan.io/address/0x5F5FF4645e65be98eCEDdCCf24e647255e65F3ca  
**Type:** Soulbound Token / On-chain Reputation

ERC721 non-transferable badge with fully on-chain SVG metadata and 3-tier reputation system (Builder / Contributor / Legend). Supports mint, tier upgrade, and revoke. All transfers are permanently blocked at contract level.

---

## Pharos Registry Contract

**Network:** Pharos Atlantic Testnet 
**Address:** https://pharosscan.io/address/0x50c91d2156c62Ca6a3b1BC39EAab379581C73510
**Type:** On-chain Registry / User Index


Simple onchain registry allowing wallets to register and be tracked inside the Pharos ecosystem.
```
epoch snapshots every 200 blocks, auto-claim on re-stake, and emergency withdraw with penalty.
