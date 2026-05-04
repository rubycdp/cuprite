# frozen_string_literal: true

module Capybara
  module Cuprite
    module Devices
      # It's idiomatic to merge other options into these, so freezing
      # isn't the right thing to do.
      IPHONE_14 = { window_size: [390, 844], mobile: true, scale_factor: 3 } # rubocop:disable Style/MutableConstant
    end
  end
end
