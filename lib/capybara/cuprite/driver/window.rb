# frozen_string_literal: true

require "capybara/cuprite/driver/window/frames"
require "capybara/cuprite/driver/window/modals"

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      # What Cuprite keeps for each of Capybara's windows next to Ferrum's page: the frame switched to and the
      # dialogs to answer.
      # @api private
      class Window
        include Frames
        include Modals

        # @return [Ferrum::Page]
        attr_reader :page

        # @param page [Ferrum::Page]
        # @param settings [Settings] the options only Cuprite handles
        def initialize(page, settings)
          @page = page
          @settings = settings
          @frame_stack = []
          @accept_modal = []
          @modal_messages = Thread::Queue.new
          @modal_response = nil
          @unhandled_modal_error = nil
          page.on(:dialog) { |dialog| handle_dialog(dialog) }
        end
      end
    end
  end
end
