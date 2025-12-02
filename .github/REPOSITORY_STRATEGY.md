# 🗂️ Repository Strategy Guide

## Current Repository Structure

### 📂 synapse-protocol (PUBLIC - THIS REPO)
**Purpose:** Core open source infrastructure  
**License:** AGPLv3 + Commercial  
**Contains:**
- Core Rust library (synapse-core, synapse-infra, synapse-cli)
- Basic adapters (LanceDB, Sled, ORT)
- Documentation and examples
- Issue tracking

**Who uses this:**
- Open source developers
- Researchers
- Personal projects
- Evaluation/testing by enterprises

---

## Future Repository Strategy

### When to Create Private Repositories

#### ✅ Create Private Repo For:

1. **Enterprise-Only Features**
   - Repository: `synapse-enterprise` (Private)
   - Contents: Premium adapters, compliance modules, SaaS infrastructure
   - Who has access: Paying customers only

2. **Proprietary Applications**
   - Repository: `orion-health-backend` (Private)
   - Contents: Business logic, trained models, production configs
   - Who has access: Your company only

3. **Customer-Specific Implementations**
   - Repository: `customer-name-synapse-deployment` (Private)
   - Contents: Custom integrations, configurations
   - Who has access: Specific customer + your team

#### ❌ Keep Public For:

1. **Core Technology**
   - THIS repo (synapse-protocol) stays public
   - Community contributions
   - SEO and visibility

2. **Demo Applications**
   - Repository: `orion-health` (Public)
   - Contents: Example UI, SDK usage examples
   - Purpose: Show potential customers what's possible

3. **Documentation & Tutorials**
   - Repository: `synapse-docs` (Public)
   - Contents: Guides, tutorials, architecture docs
   - Purpose: Education and adoption

---

## Recommended Structure (Full Ecosystem)

```
📂 synapse-protocol (PUBLIC) ⭐
   └── Core open source infrastructure
       License: AGPLv3 + Commercial

📂 synapse-enterprise (PRIVATE) 🔒
   └── Premium features (medical adapters, compliance)
       License: Proprietary
       Access: Paying customers

📂 synapse-models (PRIVATE) 🔒
   └── Trained LoRA adapters
       License: Proprietary
       Access: Enterprise tier customers

📂 orion-health (PUBLIC) 🌐
   └── Demo application (UI only)
       License: MIT (demo code)

📂 orion-health-backend (PRIVATE) 🔒
   └── Production API and business logic
       License: Proprietary
       Access: South West Labs only

📂 synapse-docs (PUBLIC) 📚
   └── Documentation website
       License: CC BY 4.0
```

---

## Decision Tree: Should This Be Private?

```
┌─ Does it contain trade secrets? ────YES──→ PRIVATE
│
├─ Does it contain customer data? ────YES──→ PRIVATE
│
├─ Is it a premium paid feature? ─────YES──→ PRIVATE
│
├─ Could competitors copy and compete? ─┬─YES──→ Consider private
│                                        └─NO ──→ PUBLIC
│
└─ Would making it public attract 
   customers/contributors? ──────────────YES──→ PUBLIC ✅
```

---

## Current Status

**As of December 2025:**

| Repository | Status | Visibility | Purpose |
|------------|--------|------------|---------|
| synapse-protocol | ✅ Created | Public | Core infrastructure |
| synapse-enterprise | ⏳ Not created yet | Private | Premium features |
| orion-health | ⏳ Future | Public | Demo app |
| orion-health-backend | ⏳ Future | Private | Production API |

---

## Migration Guide: If You Already Made It Public

**Scenario:** You accidentally published something that should be private.

**Option 1: Archive and Start Fresh (RECOMMENDED)**
```bash
# Archive the public repo
gh repo archive iberi22/synapse-protocol

# Create new private repo
gh repo create iberi22/synapse-protocol-v2 --private

# Push code to new repo
git remote set-url origin https://github.com/iberi22/synapse-protocol-v2.git
git push -u origin main
```

**Option 2: Make Existing Repo Private**
```bash
# WARNING: Loses stars, forks, SEO
gh repo edit iberi22/synapse-protocol --visibility private
```

**⚠️ IMPORTANT:** Once code is public, it's public forever (Git history, forks, archives). Only make private if it was pushed within hours and had no stars/forks.

---

## SEO Impact Analysis

### Public Repo Benefits:
- ✅ Google indexes pages
- ✅ GitHub trending potential
- ✅ Stars = social proof
- ✅ Backlinks from forks
- ✅ Developer discovery

### Private Repo Trade-offs:
- ❌ Zero SEO value
- ❌ No organic discovery
- ❌ Requires paid marketing
- ✅ Complete IP control

**Recommendation:** Keep core public, premium features private.

---

## For Your Case: synapse-protocol

**My recommendation:** ✅ **KEEP IT PUBLIC**

**Why:**
1. AGPLv3 already protects you commercially
2. You have NO competitors yet (first-mover advantage)
3. SEO benefits > IP secrecy
4. Community will build features for free
5. Credibility attracts enterprise customers

**What to make private later:**
- Medical LoRA adapters (synapse-enterprise)
- OrionHealth production backend
- Customer deployments

---

## Questions?

If unsure whether to make something public or private, ask:
1. **"Does this help competitors more than it helps me?"**
   - If NO → Public
   - If YES → Private

2. **"Can I monetize this through open core?"**
   - If YES → Public (with premium tier)
   - If NO → Private

3. **"Will this attract contributors/customers?"**
   - If YES → Public
   - If NO → Private

---

*Need help deciding? Open a GitHub Discussion in this repo.*
