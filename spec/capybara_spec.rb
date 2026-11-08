# frozen_string_literal: true

Capybara::SpecHelper.run_specs TestSessions::Cuprite, "Cuprite", capybara_skip: %i[response_headers]
