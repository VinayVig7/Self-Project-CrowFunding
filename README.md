# CrowFunding DApp

A simple and secure crowdfunding smart contract built in Solidity using Foundry. Contributors can fund a project, and the owner can withdraw funds if the goal is met. Otherwise, contributors can withdraw their funds.

---

## 🚀 Features

- Only accepts contributions above a minimum threshold.
- Has a funding goal and deadline.
- Owner can claim funds only if the goal is met.
- Contributors can withdraw if funding fails.
- Supports direct ETH sending using `receive()` and protects against fallback misuse.

---

## 🧱 Contract Details

### Constructor

```solidity
constructor(uint256 goal, uint256 minimumContribution)
```

- `goal`: The funding goal in wei.
- `minimumContribution`: Minimum contribution amount in wei.

---

### Main Functions

| Function                     | Description                                          |
|-----------------------------|------------------------------------------------------|
| `contribute()`              | Allows users to contribute ETH.                      |
| `claimFunds()`              | Owner claims funds if goal is met.                   |
| `withdraw()`                | Contributors withdraw if funding fails.              |
| `getBalance()`              | Returns current contract balance.                    |
| `getContribution(address)`  | Returns amount contributed by a user.                |
| `getStatus()`               | Returns current status: FUNDING, SUCCESSFUL, FAILED. |

---

### Fallback & Receive

```solidity
receive() external payable;
fallback() external payable;
```

- `receive()` forwards plain ETH to `contribute()`.
- `fallback()` reverts with a custom error to prevent accidental or incorrect calls.

---

## 🧪 Testing

Tests are written using Foundry in the `/test` directory.

Run all tests:

```bash
forge test
```

To test a specific function or file:

```bash
forge test --match-path test/YourTestFile.t.sol
```

---

## ⚙️ Deployment

### Script: `DeployCrowFunding.s.sol`

```solidity
contract DeployCrowFunding is Script {
    function run() external {
        vm.startBroadcast();
        new CrowFunding(0.1 ether, 0.001 ether);
        vm.stopBroadcast();
    }
}
```

### Run Deployment

```bash
forge script script/DeployCrowFunding.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

---

## 🧰 Foundry Commands

| Command                             | Description                         |
|------------------------------------|-------------------------------------|
| `forge build`                      | Compiles the contract               |
| `forge test`                       | Runs the test suite                 |
| `forge script ...`                | Deploy via script                   |
| `forge coverage`                   | Checks test coverage                |
| `forge clean`                      | Cleans build artifacts              |

---

## 📁 Project Structure

```
├── src/
│   └── CrowFunding.sol           # Main contract
├── script/
│   └── DeployCrowFunding.s.sol   # Deployment script
├── test/
│   └── CrowFunding.t.sol         # Unit tests
├── foundry.toml                  # Foundry config
└── README.md                     # You're here!
```

---

## 🔒 Security Considerations

- All ETH transfers use `.call()` and are checked for success.
- Custom errors reduce gas usage and improve clarity.
- Mappings ensure safe contributor tracking.

---

## 👨‍💻 Author

Vinay Vig
