#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../lib/aptos_wallet'

options = {
  endpoints: {
    'devnet' => 'https://fullnode.devnet.aptoslabs.com/v1',
    'testnet' => 'https://fullnode.testnet.aptoslabs.com/v1'
  }
}

OptionParser.new do |opts|
  opts.banner = 'Usage: bundle exec ruby bin/ping_endpoints.rb [options]'

  opts.on('--endpoint NAME=URL', 'Add or override an endpoint (can be passed multiple times)') do |pair|
    name, url = pair.split('=', 2)
    raise OptionParser::InvalidArgument, "Invalid endpoint format: #{pair}" unless name && url

    options[:endpoints][name] = url
  end

  opts.on('--env', 'Include endpoints from APTOS_NODE_URL and APTOS_FAUCET_URL') do
    node = ENV['APTOS_NODE_URL']
    faucet = ENV['APTOS_FAUCET_URL']
    options[:endpoints]['env_node'] = node if node
    options[:endpoints]['env_faucet'] = faucet if faucet
  end
end.parse!

puts 'Checking Aptos endpoints:'
options[:endpoints].each do |name, url|
  print "- #{name} (#{url}) ... "
  begin
    client = AptosWallet::Client.new(base_url: url)
    info = client.ledger_info
    chain_id = info['chain_id']
    timestamp = info['ledger_timestamp']
    puts "OK (chain_id=#{chain_id}, ledger_timestamp=#{timestamp})"
  rescue StandardError => e
    puts "FAILED (#{e.class}: #{e.message})"
  end
end

if options[:endpoints].empty?
  warn 'No endpoints were provided. Use --endpoint name=url to supply one.'
end
