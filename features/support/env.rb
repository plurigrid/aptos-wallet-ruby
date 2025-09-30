# frozen_string_literal: true

require 'rspec/expectations'
require 'aptos_wallet'

World(RSpec::Matchers)

DEFAULTS = {
  'APTOS_NODE_URL' => 'https://fullnode.devnet.aptoslabs.com/v1',
  'APTOS_FAUCET_URL' => 'https://faucet.devnet.aptoslabs.com'
}.freeze

DEFAULTS.each do |key, value|
  ENV[key] ||= value
end
