# frozen_string_literal: true

module Capybara::Cuprite::NetworkTraffic
  class Response
    def initialize(data)
      @data = data
    end

    def id
      @data["id"]
    end

    def url
      @data["url"]
    end

    def status
      @data["status"]
    end

    def status_text
      @data["statusText"]
    end

    def headers
      @data["headers"]
    end

    # FIXME: didn't check if we have it on redirect response
    def redirect_url
      @data["redirectURL"]
    end

    def body_size
      @body_size ||= @data.dig("headers", "Content-Length").to_i
    end

    def content_type
      @content_type ||= @data.dig("headers", "contentType").sub(/;.*\z/, "")
    end
  end
end
