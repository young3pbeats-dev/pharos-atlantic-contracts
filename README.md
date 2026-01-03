# Pharos Atlantic Contracts

Minimal Solidity contracts deployed on Pharos Atlantic Testnet.

---

## CounterLite.sol
**Network:** Pharos Atlantic Testnet  
**Address:** https://atlantic.pharosscan.xyz/address/0x5C740823bD4aBBCFA72FC6ca91E9bdBa6Cb03907

---

## PharosHello.sol
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
