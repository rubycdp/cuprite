# frozen_string_literal: true

# Once a Ferrum release has rubycdp/ferrum#733, delete this file, sig/capybara/cuprite/context.rbs and its require in
# lib/capybara/cuprite.rb, and raise the gemspec's ferrum requirement to that release.
module Ferrum
  class Context
    module NewWindow
      # Creates a new target in this context, as Ferrum's `create_target` does once rubycdp/ferrum#733 is released.
      #
      # @param new_window [Boolean] opens the target in a window of its own instead of a tab
      # @return [Ferrum::Target]
      # @raise [Ferrum::NoSuchTargetError, Ferrum::TimeoutError]
      def create_target(new_window: false)
        options = {}
        options[:browserContextId] = @id unless implicit?
        options[:newWindow] = true if new_window
        deadline = Deadline.wrap(@client.timeout)
        response = @client.command("Target.createTarget", timeout: deadline, url: "about:blank", **options)
        @targets.await(response["targetId"], deadline) || raise(NoSuchTargetError)
      end
    end

    prepend NewWindow unless instance_method(:create_target).parameters.include?(%i[key new_window])
  end
end
