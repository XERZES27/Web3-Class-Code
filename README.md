## Usage

- Run anvil forking with your respective sepolia RPC endpoint.
- Make the test calls by forking the local anvil instance usually hosted at http://127.0.0.1:8545

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test --match-contract CometTest --fork-url http://127.0.0.1:8545 -vvvv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil --fork-url <your_ankr_rpc>
```

### Deploy

```shell
$ forge script script/Compound.s.sol:CometScript --rpc-url http://127.0.0.1:8545 --private-key <your_private_key> -vvvv --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
