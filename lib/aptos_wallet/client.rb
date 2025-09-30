# frozen_string_literal: true

require 'faraday'
require 'json'
require 'cgi'
require 'sha3'
require_relative 'version'

module AptosWallet
  # Thin wrapper around the Aptos REST API for devnet/testnet usage.
  class Client
    DEFAULT_COIN_RESOURCE = '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>'
    DEFAULT_METADATA_ADDRESS = '0xa'
    FA_STORE_RESOURCE = '0x1::fungible_asset::FungibleStore'
    FA_CONCURRENT_RESOURCE = '0x1::fungible_asset::ConcurrentFungibleBalance'
    FA_STORE_SUFFIX = "\xFC".b

    attr_reader :connection

    def initialize(base_url: ENV.fetch('APTOS_NODE_URL', 'https://fullnode.devnet.aptoslabs.com/v1'), timeout: 15)
      @connection = Faraday.new(url: base_url) do |f|
        f.headers['Accept'] = 'application/json'
        f.headers['Accept-Encoding'] = 'identity'
        f.headers['User-Agent'] = "aptos-wallet-ruby/#{AptosWallet::VERSION}"
        f.response :raise_error
        f.options[:timeout] = timeout
        f.adapter Faraday.default_adapter
      end
    end

    def account(address)
      get("/accounts/#{address}")
    rescue Faraday::ResourceNotFound
      nil
    rescue Faraday::Error => e
      status, body = extract_response(e)
      raise HttpError.new("Failed to fetch account: #{e.message}", status: status, body: body)
    end

    def ledger_info
      response = with_retries { connection.get('') }
      body = response.body.to_s
      return JSON.parse(body) unless body.empty?

      header_info = {
        'chain_id' => header_int(response.headers['x-aptos-chain-id']),
        'ledger_version' => response.headers['x-aptos-ledger-version'],
        'oldest_ledger_version' => response.headers['x-aptos-ledger-oldest-version'],
        'ledger_timestamp' => response.headers['x-aptos-ledger-timestampusec'],
        'epoch' => response.headers['x-aptos-epoch'],
        'block_height' => response.headers['x-aptos-block-height'],
        'oldest_block_height' => response.headers['x-aptos-oldest-block-height']
      }.compact
      return header_info unless header_info.empty?

      raise HttpError.new('Ledger info response was empty', status: response.status, body: body)
    rescue JSON::ParserError => e
      raise HttpError.new("Failed to parse ledger info: #{e.message}", status: response.status, body: response.body)
    rescue Faraday::Error => e
      status, raw_body = extract_response(e)
      raise HttpError.new("Failed to fetch ledger info: #{e.message}", status: status, body: raw_body)
    end

    def account_exists?(address)
      !account(address).nil?
    end

    def account_balance(address, coin_resource: DEFAULT_COIN_RESOURCE, metadata_address: DEFAULT_METADATA_ADDRESS)
      balances = []
      coin_balance = fetch_coin_store_balance(address, coin_resource)
      balances << coin_balance if coin_balance

      if metadata_address
        fa_balance = fetch_fungible_store_balance(address, metadata_address)
        balances << fa_balance if fa_balance
      end

      balances.compact.max || 0
    end

    def wait_for_balance(address, minimum:, timeout: 30, interval: 2)
      deadline = Time.now + timeout
      loop do
        return true if account_balance(address) >= minimum
        raise FundingTimeout, "Balance did not reach #{minimum} before timeout" if Time.now >= deadline

        sleep interval
      end
    end

    private

    def get(path)
      normalized = path.start_with?('/') ? path[1..] : path
      response = with_retries { connection.get(normalized) }
      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise e unless e.respond_to?(:response)

      status, body = extract_response(e)
      raise HttpError.new("GET #{path} failed with status #{status}", status: status, body: body)
    end

    def extract_response(error)
      response = error.respond_to?(:response) ? error.response : nil
      return [nil, nil] unless response

      [response[:status], response[:body]]
    end

    def with_retries(max_attempts: 3, base_delay: 0.5)
      attempts = 0
      begin
        attempts += 1
        yield
      rescue Faraday::Error => e
        raise e if attempts >= max_attempts

        sleep(base_delay * attempts)
        retry
      end
    end

    def header_int(value)
      return unless value

      Integer(value)
    rescue ArgumentError
      nil
    end

    def fetch_coin_store_balance(address, coin_resource)
      resource_path = "/accounts/#{address}/resource/#{CGI.escape(coin_resource)}"
      body = get(resource_path)
      body.fetch('data').fetch('coin').fetch('value').to_i
    rescue Faraday::ResourceNotFound
      nil
    rescue HttpError => e
      return nil if e.status == 404
      raise e
    rescue KeyError => e
      raise Error, "Unexpected balance payload: #{e.message}"
    rescue Faraday::Error => e
      status, body = extract_response(e)
      raise HttpError.new("Failed to fetch balance: #{e.message}", status: status, body: body)
    end

    def fetch_fungible_store_balance(address, metadata_address)
      store_address = primary_fungible_store_address(address, metadata_address)
      store_path = "/accounts/#{store_address}/resource/#{CGI.escape(FA_STORE_RESOURCE)}"
      body = get(store_path)
      data = body.fetch('data')
      balance = data['balance']
      return balance.to_i if balance

      concurrent_path = "/accounts/#{store_address}/resource/#{CGI.escape(FA_CONCURRENT_RESOURCE)}"
      concurrent_body = get(concurrent_path)
      concurrent_body.fetch('data').fetch('balance').to_i
    rescue Faraday::ResourceNotFound
      nil
    rescue HttpError => e
      return nil if e.status == 404
      raise e
    rescue KeyError => e
      raise Error, "Unexpected fungible store payload: #{e.message}"
    rescue Faraday::Error => e
      status, body = extract_response(e)
      raise HttpError.new("Failed to fetch fungible store: #{e.message}", status: status, body: body)
    end

    def primary_fungible_store_address(account_address, metadata_address)
      input = String.new(encoding: Encoding::BINARY)
      input << hex_to_bytes(account_address)
      input << hex_to_bytes(metadata_address)
      input << FA_STORE_SUFFIX
      "0x#{SHA3::Digest::SHA256.hexdigest(input)}"
    end

    def hex_to_bytes(hex)
      cleaned = hex.to_s.delete_prefix('0x').rjust(64, '0')
      [cleaned].pack('H*').b
    end
  end
end
