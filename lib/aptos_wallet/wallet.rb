# frozen_string_literal: true

module AptosWallet
  # High-level convenience wrapper representing a devnet wallet.
  class Wallet
    attr_reader :keypair, :client, :faucet

    def self.generate(client: Client.new, faucet: Faucet.new)
      new(keypair: Keypair.generate, client: client, faucet: faucet)
    end

    def initialize(keypair:, client:, faucet:)
      @keypair = keypair
      @client = client
      @faucet = faucet
    end

    def address
      keypair.address
    end

    def public_key_hex
      keypair.public_key_hex
    end

    def private_key_hex
      keypair.private_key_hex
    end

    def fund!(amount, wait: true, min_wait: amount, timeout: 60)
      faucet.fund_account(address, amount)
      return unless wait

      client.wait_for_balance(address, minimum: min_wait, timeout: timeout)
    end

    def balance
      client.account_balance(address)
    end

    def exists_on_chain?
      client.account_exists?(address)
    end
  end
end
