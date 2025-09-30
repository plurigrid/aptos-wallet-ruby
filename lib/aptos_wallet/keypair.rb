# frozen_string_literal: true

require 'ed25519'
require 'sha3'

module AptosWallet
  # Represents an Ed25519 key pair compatible with Aptos accounts.
  class Keypair
    KEY_SCHEME = "\x00".b

    attr_reader :signing_key

    def self.generate
      new(Ed25519::SigningKey.generate)
    end

    def self.from_seed(seed_bytes)
      raise ArgumentError, 'Seed must be 32 bytes' unless seed_bytes.bytesize == 32

      new(Ed25519::SigningKey.new(seed_bytes))
    end

    def initialize(signing_key)
      @signing_key = signing_key
    end

    def verifying_key
      signing_key.verify_key
    end

    def private_key_hex
      signing_key.to_bytes.unpack1('H*')
    end

    def public_key_hex
      verifying_key.to_bytes.unpack1('H*')
    end

    def address
      @address ||= begin
        digest = SHA3::Digest::SHA256.new
        digest.update(verifying_key.to_bytes)
        digest.update(KEY_SCHEME)
        "0x#{digest.hexdigest}"
      end
    end
  end
end
