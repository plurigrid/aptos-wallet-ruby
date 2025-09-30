# frozen_string_literal: true

require 'aptos_wallet'

Given('an Aptos devnet client') do
  @aptos_client = AptosWallet::Client.new
  @aptos_faucet = AptosWallet::Faucet.new
end

When('I create a fresh devnet wallet') do
  @wallet = AptosWallet::Wallet.generate(client: @aptos_client, faucet: @aptos_faucet)
end

When('I fund the wallet with {int} Octas') do |amount|
  raise 'wallet not initialised' unless @wallet

  @wallet.fund!(amount, timeout: 90)
end

Then('the wallet balance should be at least {int} Octas') do |amount|
  raise 'wallet not initialised' unless @wallet

  expect(@wallet.balance).to be >= amount
end
