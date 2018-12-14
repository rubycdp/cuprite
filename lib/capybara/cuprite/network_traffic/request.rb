# frozen_string_literal: true

require "time"

module Capybara::Cuprite::NetworkTraffic
  class Request
    attr_reader :response_parts
    attr_accessor :error

    def initialize(data, response_parts = nil)
      @data           = data
      @response_parts = Array(response_parts)
    end

    def id
      @data["id"]
    end

    def url
      @data["url"]
    end

    def method
      @data["method"]
    end

    def headers
      @data["headers"]
    end

    def time
      @time ||= Time.strptime(@data["time"].to_s, "%s")
    end
  end
end
