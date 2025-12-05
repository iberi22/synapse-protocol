---
title: "Synapse Protocol - Tokenomics & Business Model"
type: ECONOMICS
id: "eco-synapse-v1"
created: 2025-12-03
status: DRAFT
---

# 🪙 Synapse Economic Model (The "Collective Consciousness" Economy)

## 1. Token Distribution Strategy (The "Halving" Curve)

To incentivize early adoption while preventing hyper-inflation, we use a continuous decay function based on the number of verified human users.

### The Formula
$$ Reward(u) = 1,000,000 \times 2^{-(u / 1,000,000)} $$

Where:
- $u$ = Current number of verified human users.
- $Reward(u)$ = Tokens minted for user $u$.

### Milestones
| User # (u) | Reward ($SYN) | Status |
|------------|---------------|--------|
| 1          | 1,000,000     | Genesis |
| 250,000    | 840,896       | Early Adopter |
| 500,000    | 707,106       | Growth Phase |
| 750,000    | 594,603       | Mass Adoption |
| **1,000,000** | **500,000** | **The Halving** |
| 2,000,000  | 250,000       | Maturity |
| 10,000,000 | 976           | Saturation |

### Total Supply Analysis
- **Theoretical Max Supply**: ~1.44 Trillion $SYN (if user count $\to \infty$).
- **Vesting**:
  - **20%**: Liquid immediately (for gas/initial commerce).
  - **80%**: Locked in "Synapse Vault".
  - **Unlock Schedule**: 10% of the *original locked amount* releases every year for 8 years.

---

## 2. Commerce of Information (The Marketplace)

Users can monetize their "MemoryNodes" (data) without compromising privacy.

### Mechanism: "Compute-over-Data" (CoD)
Instead of selling raw data (files, chats), users sell **access to insights**.

1.  **Buyer** (e.g., Company) requests: "Sentiment analysis of Gen Z users regarding Climate Change."
2.  **Network** propagates the request to relevant users (filtered by `GenesisBlock` ethics).
3.  **User Node** (Local) processes the request using its own LLM + Vector Store.
4.  **Result** (Anonymized aggregate) is sent back.
5.  **Payment** ($SYN) is transferred from Buyer to User.

### Privacy Guarantee
- Raw data **NEVER** leaves the device.
- Only the *result* of the computation (inference) is transmitted.
- Zero-Knowledge Proofs (ZKP) verify the user is human and the data is real.

---

## 3. Fundraising: SouthWest Labs Equity

To raise capital for the laboratory ("SouthWest Labs"), we introduce two asset classes:

### A. $LABS (Security Token / Equity)**
- **Represents**: Actual ownership/shares in SouthWest Labs.
- **Rights**: Dividends from protocol fees (e.g., 1% of all data commerce).
- **Target**: VCs, Angel Investors.
- **Legal**: Requires Regulation D/S compliance (US) or equivalent.

### B. "Neoteny Nodes" (License Sale)
- **Concept**: Sell 10,000 "Genesis Node" licenses.
- **Benefit**: These nodes get a multiplier on data sales and governance rights.
- **Price**: Tiered (e.g., first 1000 @ $500, next @ $1000).
- **Goal**: Raise immediate operating capital (non-dilutive).

---

## 4. System Permissions & "Memory Level" Access

To achieve "Collective Consciousness" without being flagged as malware:

### The "Deep Context" Protocol
Instead of raw RAM access (which triggers Antivirus), we use **OS Accessibility & Hooking APIs**:

1.  **Screen Context**: OCR (Optical Character Recognition) on active windows (like Microsoft Recall).
2.  **Input Context**: Keyboard/Mouse pattern analysis (User-approved).
3.  **App State**: Reading public window handles and accessibility trees.

**Implementation (Rust/Tauri):**
- Use `accessibility-rs` or platform-specific crates (`windows`, `cocoa`).
- **User Consent**: Must be explicitly granted "Accessibility Permission" in OS settings.
- **Visual Indicator**: A "Neural Link" icon always visible when recording context.

---

## 5. MVP Roadmap (Commerce Focus)

1.  **Identity**: Implement `ProofOfSentience` (Simple captcha/device fingerprint initially).
2.  **Wallet**: Integrate a lightweight crypto wallet in the Tauri app.
3.  **Marketplace**: A simple "Data Request" board where users can opt-in to answer surveys/share insights for dummy tokens.
