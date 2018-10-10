# frozen_string_literal: true

require "spec_helper"

module Capybara::Cuprite
  describe Driver, skip: true do
    context "with no options" do
      subject { Driver.new(nil) }

      it "does not log" do
        expect(subject.logger).to be_nil
      end
    end

    context "with a :logger option" do
      subject { Driver.new(nil, logger: :my_custom_logger) }

      it "logs to the logger given" do
        expect(subject.logger).to eq(:my_custom_logger)
      end
    end

    context "with a :timeout option" do
      subject { Driver.new(nil, timeout: 3) }

      it "starts the server with the provided timeout" do
        server = double
        expect(Server).to receive(:new).with(anything, 3, nil).and_return(server)
        expect(subject.server).to eq(server)
      end
    end

    context "with a :window_size option" do
      subject { Driver.new(nil, window_size: [800, 600]) }

      it "creates a client with the desired width and height settings" do
        server = double
        expect(Server).to receive(:new).and_return(server)
        expect(Client).to receive(:start).with(server, hash_including(window_size: [800, 600]))

        subject.client
      end
    end
  end
end
