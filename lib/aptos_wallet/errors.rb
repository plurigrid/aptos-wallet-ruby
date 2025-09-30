# frozen_string_literal: true

module AptosWallet
  class Error < StandardError; end

  class HttpError < Error
    attr_reader :status, :body

    def initialize(message, status:, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class FaucetError < Error; end

  class FundingTimeout < Error; end
end
