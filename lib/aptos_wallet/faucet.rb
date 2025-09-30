# frozen_string_literal: true

require 'faraday'
require 'json'

module AptosWallet
  # Simple client for the Aptos faucet service (devnet/testnet only).
  class Faucet
    attr_reader :connection

    def initialize(base_url: ENV.fetch('APTOS_FAUCET_URL', 'https://faucet.devnet.aptoslabs.com'), timeout: 15)
      @connection = Faraday.new(url: base_url) do |f|
        f.response :raise_error
        f.options[:timeout] = timeout
        f.adapter Faraday.default_adapter
      end
    end

    def fund_account(address, amount, coin_type: '0x1::aptos_coin::AptosCoin')
      response = connection.post('mint') do |req|
        req.params['address'] = address
        req.params['amount'] = amount.to_s
        req.params['coin_type'] = coin_type if coin_type
      end

      body = response.body
      body.empty? ? [] : JSON.parse(body)
    rescue Faraday::Error => e
      response = e.respond_to?(:response) ? e.response : {}
      status = response[:status]
      body = response[:body]
      raise FaucetError, "Faucet mint failed (status=#{status}): #{body || e.message}"
    end
  end
end
