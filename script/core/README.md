# Deployment scripts

This folder contains the scripts neccessary to deploy strategies and Allo contracts to the blockchain.

# Usage

1. Install dependencies by running `bun install`.
2. Compile contracts by running `bun smock && bun compile`.
3. Fill the necessary environment variables in `.env` file. You can use `.env.example` as a template.
4. Run the deployment script with:
```
bun run deploy-allo-v2.1 <CHAIN>
```
For example:
```
bun run deploy-allo-v2.1 sepolia
```
For more deployment [options](https://book.getfoundry.sh/reference/forge/forge-script) run with `forge script` directly:
```
forge script ${SCRIPT_CONTRACT_NAME} --fork-url ${RPC_URL} --private-key ${PRIVATE_KEY} --broadcast
```
For example:
```
forge script DeployAllo --fork-url https://eth-sepolia.public.blastapi.io --private-key 0x0000 --broadcast
```