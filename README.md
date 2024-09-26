# Decentralized Compute and Storage Platform

## Overview

This project implements a decentralized compute and storage platform using smart contracts on the Stacks blockchain. It allows users to register as storage or compute providers, lease resources from these providers, and manage their leases.

## Features

- Registration and management of storage nodes
- Registration and management of compute nodes
- Leasing of storage space
- Leasing of compute resources
- Payment system for leases
- Lease extension functionality

## Smart Contract Functions

### Storage Node Management

- `register-storage-node`: Register a new storage node
- `update-storage-node`: Update an existing storage node's details

### Compute Node Management

- `register-compute-node`: Register a new compute node
- `update-compute-node`: Update an existing compute node's details

### Resource Leasing

- `lease-storage`: Lease storage space from a node
- `lease-compute`: Lease compute resources from a node

### Payments

- `pay-storage-lease`: Pay for a storage lease
- `pay-compute-lease`: Pay for a compute lease

### Lease Management

- `extend-storage-lease`: Extend the duration of a storage lease
- `extend-compute-lease`: Extend the duration of a compute lease

## Security Features

- Input validation for all user-provided data
- Maximum limits on resource quantities and prices
- Ownership checks for node updates
- Lease duration limits

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): A Clarity runtime packaged as a command line tool
- [Stacks Wallet](https://www.hiro.so/wallet): For interacting with the Stacks blockchain

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/decentralized-compute-storage.git
   cd decentralized-compute-storage
   ```

2. Install dependencies:
   ```
   clarinet requirements
   ```

3. Test the smart contract:
   ```
   clarinet test
   ```

### Deployment

1. Configure your Stacks wallet with sufficient STX for deployment.

2. Deploy the contract to the Stacks blockchain:
   ```
   clarinet deploy
   ```

## Usage

Interact with the deployed contract using the Stacks CLI or integrate it into your dApp using the [Stacks.js library](https://github.com/hirosystems/stacks.js).

Example of registering a storage node:

```javascript
const contractAddress = 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9';
const contractName = 'decentralized-compute-storage';

const txOptions = {
  contractAddress,
  contractName,
  functionName: 'register-storage-node',
  functionArgs: [uintCV(1000000), uintCV(10)],
  senderKey: 'your-private-key',
  validateWithAbi: true,
  network: 'mainnet',
};

const transaction = await makeContractCall(txOptions);
const result = await broadcastTransaction(transaction, network);
console.log(result);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This smart contract is a prototype and has not been audited. Use at your own risk in production environments.


This README provides a comprehensive overview of the decentralized compute and storage project. It includes:

1. A brief introduction to the project
2. Key features
3. Detailed list of smart contract functions
4. Security features implemented
5. Getting started guide, including prerequisites and installation steps
6. Deployment instructions
7. Usage example with JavaScript code
8. Sections for contributing and license information
9. A disclaimer about the project's current state

This README should give potential users and contributors a good understanding of what the project does, how to set it up, and how to use it. It also provides a solid foundation for further documentation as the project evolves.