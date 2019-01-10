# frozen_string_literal: true

require "spec_helper"
require "stringio"

module Capybara::Cuprite
  describe Browser do
    context "with a logger" do
      let(:logger) { StringIO.new }
      subject      { Browser.new(logger: logger) }

      it "logs requests and responses to the server" do
        subject.body

        expect(logger.string).to include("return document.documentElement.outerHTML")
        expect(logger.string).to include("<html><head></head><body></body></html>")
      end
    end
  end
end
