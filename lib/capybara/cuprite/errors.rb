# frozen_string_literal: true

module Capybara
  module Cuprite
    class Error < StandardError; end

    class ClientError < Error
      attr_reader :response

      def initialize(response)
        @response = response
        super()
      end
    end

    class InvalidSelector < ClientError
      def initialize(response, method, selector)
        super(response)
        @method = method
        @selector = selector
      end

      def message
        "Browser raised error trying to find #{@method}: #{@selector.inspect}"
      end
    end

    class MouseEventFailed < ClientError
      attr_reader :name, :selector, :position

      def initialize(*)
        super
        data = /\A\w+: (\w+), (.+?), ([\d.-]+), ([\d.-]+)/.match(@response)
        @name, @selector = data.values_at(1, 2)
        @position = data.values_at(3, 4).map(&:to_f)
      end

      def message
        "Firing a #{name} at coordinates [#{position.join(', ')}] failed. Cuprite detected " \
          "another element with CSS selector \"#{selector}\" at this position. " \
          "It may be overlapping the element you are trying to interact with. " \
          "If you don't care about overlapping elements, try using node.trigger(\"#{name}\")."
      end
    end

    class UnhandledModalError < Error
      attr_reader :message

      def initialize(message)
        @message = message
        super()
      end
    end

    FERRUM_PENDING_CONNECTIONS_ERROR = Ferrum.const_defined?(:PendingConnectionsError, false)

    class PendingConnectionsError < (FERRUM_PENDING_CONNECTIONS_ERROR ? Ferrum::PendingConnectionsError : Ferrum::StatusError)
      attr_reader :url, :pendings

      def initialize(url, pendings = [])
        super(url)
        @url = url
        @pendings = pendings
      end

      def message
        message = "Request to #{@url} reached server, but there are still pending connections"
        @pendings.empty? ? message : "#{message}: #{@pendings.join(', ')}"
      end
    end

    module DeprecatedPendingConnectionsError
      def ===(other)
        matched = super
        if matched && equal?(Ferrum::PendingConnectionsError) && other.is_a?(Cuprite::PendingConnectionsError)
          warn "Ferrum::PendingConnectionsError is deprecated, use Capybara::Cuprite::PendingConnectionsError",
               uplevel: 1
        end
        matched
      end
    end

    Ferrum::PendingConnectionsError.singleton_class.prepend(DeprecatedPendingConnectionsError) if
      FERRUM_PENDING_CONNECTIONS_ERROR

    class ObsoleteNode < ClientError
      attr_reader :node

      def initialize(node, response)
        @node = node
        super(response)
      end

      def message
        "The element you are trying to interact with is either not part of the DOM, or is " \
          "not currently visible on the page (perhaps display: none is set). " \
          "It is possible the element has been replaced by another element and you meant to interact with " \
          "the new element. If so you need to do a new find in order to get a reference to the " \
          "new element."
      end
    end
  end
end
