# ERC20 Token with Vesting and Staking

This project includes:

- ✅ A custom ERC20 token (`MyToken`)
- 🔒 A vesting contract to release tokens over time
- 💰 A staking contract to allow users to earn rewards

Built using [Foundry](https://book.getfoundry.sh/) and deployed to the **Sepolia testnet**.

---

## 🛠 Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- An RPC provider (e.g. [Alchemy](https://www.alchemy.com/))
- Sepolia ETH (get from [faucet](https://sepoliafaucet.com/))

---

## 📦 Installation

```bash
git clone https://github.com/yourusername/your-repo.git
cd your-repo
forge install
```

---

## 🧪 Running Tests

```bash
forge test
```

---

## 🔐 Create `.env` File

Create a `.env` file in the root directory of your project and add:

```env
PRIVATE_KEY=your_private_key
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_project_id
```

---

## 🚀 Deploy Contracts

Run the deployment script:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```
