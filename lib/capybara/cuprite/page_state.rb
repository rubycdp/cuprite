# frozen_string_literal: true

require "capybara/cuprite/page_state/frames"
require "capybara/cuprite/page_state/modals"

module Capybara
  module Cuprite
    # What Cuprite keeps for each page next to Ferrum's: the frame switched to and the dialogs to answer.
    # @api private
    class PageState
      include Frames
      include Modals

      # @return [Ferrum::Page]
      attr_reader :page

      # @param page [Ferrum::Page]
      # @param settings [Browser::Settings] the options only Cuprite handles
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
