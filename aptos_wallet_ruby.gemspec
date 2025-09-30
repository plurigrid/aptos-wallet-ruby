# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'aptos_wallet_ruby'
  spec.version       = '0.1.0'
  spec.summary       = 'Minimal Aptos wallet integration tooling for Cucumber BDD flows'
  spec.description   = 'Generates Aptos devnet wallets, funds via faucet, and surfaces balance/metadata helpers for BDD scenarios.'
  spec.homepage      = 'https://example.com/aptos_wallet_ruby'
  spec.license       = 'MIT'
  spec.authors       = ['IES Automation']
  spec.email         = ['dev@ies.local']

  spec.required_ruby_version = '>= 2.6'

  spec.files = Dir.glob('lib/**/*.rb') + Dir.glob('features/**/*.rb') + Dir.glob('features/**/*.feature')
  spec.add_dependency 'cucumber', '~> 8.0'
  spec.add_dependency 'ed25519', '~> 1.3'
  spec.add_dependency 'faraday', '~> 1.10'
  spec.add_dependency 'json', '>= 2.0'
  spec.add_dependency 'sha3', '~> 1.0'
  spec.add_dependency 'rspec-expectations', '~> 3.13'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
