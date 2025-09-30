# Aptos Wallet Ruby Helpers

Utilities for generating Aptos devnet accounts, funding them through the
public faucet, and asserting balances in BDD scenarios.

## Setup

1. Ensure Ruby 2.6 or newer is available (Ruby 3.x works too).
2. Keep gems vendored locally so system Rubygems permissions are not needed:
   ```bash
   bundle config set --local path 'vendor/bundle'
   bundle config set --local force_ruby_platform true
   bundle install
   ```
   The second command forces Bundler to compile native extensions such as
   `sha3` and `ed25519` for your architecture (helpful on Apple silicon).
3. Export custom node or faucet URLs if you are using providers such as
   QuickNode or an Aptos fullnode you operate yourself:
   ```bash
   export APTOS_NODE_URL="https://your-node.example.com/v1"
   export APTOS_FAUCET_URL="https://your-faucet.example.com"
   ```

## Endpoint Quick Check

Run the bundled probe to confirm which public fullnodes are reachable before
executing Cucumber flows:

```bash
bundle exec ruby bin/ping_endpoints.rb --env \
  --endpoint mainnet=https://fullnode.mainnet.aptoslabs.com/v1
```

Example output:

```
Checking Aptos endpoints:
- devnet (https://fullnode.devnet.aptoslabs.com/v1) ... OK (chain_id=34, ledger_timestamp=1727720000000)
- testnet (https://fullnode.testnet.aptoslabs.com/v1) ... OK (chain_id=43, ledger_timestamp=1727720005000)
- env_node (https://your-node.example.com/v1) ... FAILED (...)
```

`--env` folds in any `APTOS_NODE_URL`/`APTOS_FAUCET_URL` values so you can test
custom infrastructure alongside the public devnet/testnet endpoints.

## Quick Start

```ruby
require 'aptos_wallet'

client = AptosWallet::Client.new
wallet = AptosWallet::Wallet.generate(client: client, faucet: AptosWallet::Faucet.new)

wallet.fund!(1_000_000) # requests 0.01 APT from the devnet faucet and waits for confirmation
puts wallet.balance      # => integer balance in Octas
```

The Cucumber feature in `features/wallet_flows.feature` exercises the same
flow end to end.

## Balance Handling

`AptosWallet::Client#account_balance` now checks both legacy
`0x1::coin::CoinStore` resources and the modern Fungible Asset stores that
ship with Aptos' token V2 rollout. You can pass a different metadata object
address via `metadata_address:` when working with custom fungible assets.

## Troubleshooting

- **Faucet rate limits**: Devnet faucets throttle aggressively. If tests fail
  with HTTP 429, back off and retry later or point to a private faucet.
- **Native extension build failures**: Install Xcode command-line tools on macOS
  (`xcode-select --install`) so the `sha3` and `ed25519` gems compile.
- **Timeouts**: Increase `timeout:` when constructing `Client` or `Faucet`
  instances if your node is geographically distant.

## Further Reading

- Aptos official REST API documentation covers account resources, faucet
  endpoints, and Fungible Asset object addresses.
- QuickNode's Aptos guides include Ruby examples for calling fullnode APIs
  and the devnet faucet.
- The community voyage guide for Aptos' Fungible Asset standard provides a
  step-by-step walkthrough of the V2 token model and how to locate primary
  fungible stores.

## Secure Key Management with Aptos CLI Profiles

For production usage avoid storing private keys directly in environment
variables or repository files. Instead, leverage Aptos CLI profiles to manage
authentication material securely:

1. Install the Aptos CLI (https://aptos.dev/tools/aptos-cli/install-cli/).
2. Create a profile, which generates and stores keys under
   `~/.aptos/config.yaml` with filesystem permissions restricted to your user:
   ```bash
   aptos init --profile bdd-devnet --rest-url https://fullnode.devnet.aptoslabs.com/v1 \
     --faucet-url https://faucet.devnet.aptoslabs.com
   ```
3. Export profile metadata for automation without exposing private keys:
   ```bash
   export APTOS_PROFILE=bdd-devnet
   PROFILE_JSON=$(aptos config show-profiles --profile "$APTOS_PROFILE")
   export APTOS_NODE_URL="$(jq -r --arg profile "$APTOS_PROFILE" '.Result[$profile].rest_url' <<<"$PROFILE_JSON")"
   export APTOS_FAUCET_URL="$(jq -r --arg profile "$APTOS_PROFILE" '.Result[$profile].faucet_url' <<<"$PROFILE_JSON")"
   ```
4. When you need to sign transactions or rotate keys, use `aptos account`
   commands rather than writing keys to disk within this repository. Profiles
   allow separate keys per environment (devnet/testnet/mainnet) and can be
   backed by hardware wallets or stored in secret managers.
5. For CI environments, inject the profile configuration via secure secrets
   (e.g., GitHub Actions secrets or HashiCorp Vault) and load it just-in-time
   inside the workflow runner. Avoid committing `~/.aptos/config.yaml` or any
   derived keys to version control.

These practices keep Aptos credentials outside the repository while letting the
code read REST and faucet endpoints through environment variables populated by
profiles.
