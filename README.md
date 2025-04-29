# Treasure Guardian Contract 🛡️💎

A Clarity smart contract for managing a collection of unique "treasures" on the Stacks blockchain. The contract facilitates registration, metadata handling, classification tagging, access permissions, and custodianship transfer.

## Features

- 📦 **Treasure Registry**: Add and track individual treasures with custom metadata.
- 🛠️ **Custodianship Control**: Only the current custodian may update or transfer a treasure.
- 🔐 **Access Permissions**: Define which principals can interact with which treasures.
- 📜 **Lore & Metadata**: Store contextual, historical, and descriptive information.
- 🧩 **Classification Tags**: Categorical descriptors (up to 10 per treasure).
- 📈 **Immutable History**: Block height records treasure inception for on-chain provenance.

## Contract Overview

### Key Data Structures

- `treasure-repository`: Map storing metadata per treasure.
- `permission-matrix`: Map assigning access rights to principals.
- `treasure-count`: Tracks the total number of registered treasures.

### Constants

- `SOVEREIGN`: The sovereign principal with top-level privileges.
- A suite of error codes for validation and permission checks.

### Core Public Functions

- `register-treasure(...)`: Register a new treasure.
- `retrieve-lore(...)`: Fetch the treasure's lore.
- `verify-subject-permission(...)`: Check access permissions.
- `transfer-custodianship(...)`: Transfer ownership to another principal.
- `update-treasure(...)`: Update metadata (custodian-only).
- `retire-treasure(...)`: Remove a treasure from the registry.

## Usage

This smart contract is written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview), the smart contract language for the Stacks blockchain.

### Deploying

To deploy, use the Stacks CLI or an IDE like Clarinet:

```bash
clarinet deploy
