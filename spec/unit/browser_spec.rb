# frozen_string_literal: true

require "spec_helper"
require "stringio"

module Capybara::Cuprite
  describe Client do
    let(:server) { double("server").as_null_object }

    context "with a logger" do
      let(:logger) { StringIO.new }
      subject      { Client.new(server) }

      it "logs requests and responses to the server" do
        response = %({"response":"<3"})

        subject.command("where is", "the love?")

        expect(logger.string).to include(%(name":"where is","args":["the love?"]]))
        expect(logger.string).to include(response)
      end
    end
  end
end
