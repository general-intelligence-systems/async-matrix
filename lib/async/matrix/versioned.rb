# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # Included into every class built for a version.
    module Versioned
      module ClassMethods
        # @returns [Module] the generated API this class belongs to, or {Async::Matrix}.
        def api
          if self.const_defined?(:API)
            self::API
          else
            self.namespace
          end
        end

        # The API namespace this class belongs to: the module which holds it, which is one of the Matrix APIs, e.g. {Async::Matrix::ClientServer}.
        #
        # @returns [Module] the namespace.
        def namespace
          @namespace ||= begin
            parts = self.unversioned.name.split("::")

            Object.const_get(parts[0..-2].join("::"))
          end
        end

        # The class this one was built from, which is this class when it is not versioned.
        #
        # @returns [Class] the unversioned class.
        def unversioned
          self.const_defined?(:API) ? self.superclass : self
        end

        # The specification version this class implements.
        #
        # Deliberately not `VERSION`: {Async::Matrix::VERSION} is the gem's own version, and an unversioned class resolves its api to {Async::Matrix}.
        #
        # @returns [String | nil] the version, or nil if this class is not versioned.
        def version
          api = self.api

          if api.const_defined?(:SPEC_VERSION, false)
            api::SPEC_VERSION
          end
        end
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # @returns [Module] the generated API this instance's class belongs to.
      def api
        self.class.api
      end

      # @returns [String | nil] the specification version of this instance's class.
      def version
        self.class.version
      end
    end
  end
end
