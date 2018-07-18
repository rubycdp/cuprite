# frozen_string_literal: true

require "spec_helper"

module Capybara::Cuprite
  describe Client do
    let(:server) { double(port: 6000, host: "127.0.0.1") }
    let(:server_params) { {} }
    subject { Server.new(server_params) }

    unless Capybara::Cuprite.windows?
      it "forcibly kills the child if it does not respond to SIGTERM" do
        server = Server.new(server)

        allow(Process).to receive_messages(spawn: 5678)
        allow(Process).to receive(:wait).and_return(nil)

        server.start

        expect(Process).to receive(:kill).with("TERM", 5678).ordered
        expect(Process).to receive(:kill).with("KILL", 5678).ordered

        server.stop
      end
    end
  end
end
