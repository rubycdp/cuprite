# frozen_string_literal: true

require "spec_helper"

module Capybara::Cuprite
  describe Driver do
    context "with no options" do
      subject { Driver.new(nil) }

      it "instantiates sucessfully" do
        expect(subject.options).to eq({})
      end
    end

    context "with a :timeout option" do
      subject { Driver.new(nil, timeout: 3) }

      it "starts the server with the provided timeout" do
        client = double("Client").as_null_object

        expect(Browser::Client).to receive(:new).twice.with(anything, nil, 3).and_return(client)

        subject.browser
      end
    end

    context "with a :window_size option", skip: true do
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
