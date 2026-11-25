# frozen_string_literal: true

module Capybara
  module Cuprite
    # The base of Cuprite's errors.
    class Error < StandardError; end

    # An error the browser reported.
    class ClientError < Error
      # @return [Object] what the browser responded with
      attr_reader :response

      # @param response [Object] what the browser responded with
      def initialize(response)
        @response = response
        super()
      end
    end

    # Raised by the finders for a selector the browser can't parse.
    class InvalidSelector < ClientError
      # @param response [Object] what the browser responded with
      # @param method [:css, :xpath]
      # @param selector [String]
      def initialize(response, method, selector)
        super(response)
        @method = method
        @selector = selector
      end

      # @return [String]
      def message
        "Browser raised error trying to find #{@method}: #{@selector.inspect}"
      end
    end

    # Raised by a click when another element, overlapping this one, would receive it.
    class MouseEventFailed < ClientError
      # @return [String] the mouse event, like `"click"`
      attr_reader :name
      # @return [String] the CSS selector of the overlapping element
      attr_reader :selector
      # @return [Array(Float, Float)] the coordinates of the event
      attr_reader :position

      # Parses the browser's `"MouseEventFailed: <name>, <selector>, <x>, <y>"` response.
      def initialize(*)
        super
        data = /\A\w+: (\w+), (.+?), ([\d.-]+), ([\d.-]+)/.match(@response)
        @name, @selector = data.values_at(1, 2)
        @position = data.values_at(3, 4).map(&:to_f)
      end

      # @return [String]
      def message
        "Firing a #{name} at coordinates [#{position.join(', ')}] failed. Cuprite detected " \
          "another element with CSS selector \"#{selector}\" at this position. " \
          "It may be overlapping the element you are trying to interact with. " \
          "If you don't care about overlapping elements, try using node.trigger(\"#{name}\")."
      end
    end

    # Raised with `raise_on_unhandled_modal: true` when a dialog opens outside `accept_*` or `dismiss_*`.
    class UnhandledModalError < Error
      # @return [String]
      attr_reader :message

      # @param message [String]
      def initialize(message)
        @message = message
        super()
      end
    end

    # Whether this Ferrum still has `Ferrum::PendingConnectionsError`.
    # @api private
    FERRUM_PENDING_CONNECTIONS_ERROR = Ferrum.const_defined?(:PendingConnectionsError, false)

    # Raised by `visit` with `pending_connection_errors: true` when the page doesn't load in time.
    class PendingConnectionsError < (FERRUM_PENDING_CONNECTIONS_ERROR ? Ferrum::PendingConnectionsError : Ferrum::StatusError)
      # @return [String] the URL being loaded
      attr_reader :url
      # @return [Array<String>] the URLs of the requests still pending
      attr_reader :pendings

      # @param url [String] the URL being loaded
      # @param pendings [Array<String>] the URLs of the requests still pending
      def initialize(url, pendings = [])
        super(url)
        @url = url
        @pendings = pendings
      end

      # @return [String]
      def message
        message = "Request to #{@url} reached server, but there are still pending connections"
        @pendings.empty? ? message : "#{message}: #{@pendings.join(', ')}"
      end
    end

    # Warns when `rescue Ferrum::PendingConnectionsError` catches Cuprite's error.
    # @api private
    module DeprecatedPendingConnectionsError
      # @param other [Object]
      # @return [Boolean]
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

    # Raised when an element is no longer in the DOM. Capybara finds it again and retries.
    class ObsoleteNode < ClientError
      # @return [Node] the element
      attr_reader :node

      # @param node [Node] the element
      # @param response [Object, nil] what the browser responded with
      def initialize(node, response)
        @node = node
        super(response)
      end

      # @return [String]
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
