# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "error"
require_relative "versioned"

module Async
  module Matrix
    # The specification versions this library knows about, oldest first.
    #
    # The order is significant: layers are applied in this order, so a later layer sits closer to
    # the generated class than an earlier one, and therefore overrides it.
    VERSIONS = %w[
      v1.1 v1.2 v1.3 v1.4 v1.5 v1.6 v1.7 v1.8 v1.9 v1.10
      v1.11 v1.12 v1.13 v1.14 v1.15 v1.16 v1.17 v1.18 v1.19
    ].freeze

    # The most recent version this library knows about.
    LATEST = VERSIONS.last

    # Raised when asked for a version which is not one of {VERSIONS}.
    class UnsupportedVersionError < Error
      def initialize(version)
        super("Unsupported version #{version.inspect}, expected one of #{VERSIONS.join(", ")}!")

        @version = version
      end

      # @attribute [String] the version which was asked for.
      attr :version
    end

    # The version layers, which mirror the classes they are layered onto: the layers for
    # {Async::Matrix::Room} live in `Async::Matrix::Abstract::Room`, in `abstract/rooms.rb`.
    #
    # A layer is a module named after the version which introduced the behaviour, so `v1.19`
    # becomes `V1_19` - a constant cannot begin with a digit. A layer may also carry a nested
    # `ClassMethods` module, which is extended onto the class rather than included into it.
    module Abstract
    end

    # Builds a set of classes for a given specification version, by layering the modules in
    # {Abstract} onto the unversioned classes.
    module Versions
      class << self
        # Normalize a version, which may be given with or without the `v` prefix.
        #
        # @parameter version [String | Symbol] e.g. `"v1.19"`, `"1.19"`.
        # @returns [String] the canonical version, e.g. `"v1.19"`.
        # @raises [UnsupportedVersionError] if the version is not supported.
        def normalize(version)
          version = version.to_s
          unless version.start_with?("v")
            version = "v#{version}"
          end

          unless VERSIONS.include?(version)
            raise UnsupportedVersionError, version
          end

          version
        end

        # The name of the module which carries a version's implementation.
        #
        # @parameter version [String] a canonical version.
        # @returns [Symbol] the layer name, e.g. `:V1_19`.
        def layer_name(version)
          :"V#{version.delete_prefix("v").tr(".", "_")}"
        end

        # Every version up to and including the given one, oldest first.
        #
        # @parameter version [String] a canonical version.
        # @returns [Array(String)] the applicable versions.
        def up_to(version)
          VERSIONS[0..VERSIONS.index(version)]
        end

        # The layer names which apply to the given version, oldest first.
        #
        # @parameter version [String] a canonical version.
        # @returns [Array(Symbol)] the layer names.
        def layers_for(version)
          self.up_to(version).map{|applicable| self.layer_name(applicable)}
        end

        # The API built for a given specification version, which is cached: the classes for a
        # version are built once, and are identical on every subsequent lookup.
        #
        # @parameter version [String | Symbol] e.g. `"v1.19"` or `"1.19"`.
        # @returns [Module] a module containing one class per versioned class.
        def [](version, namespace = Matrix::ClientServer)
          version = self.normalize(version)

          @apis ||= {}
          @apis[[namespace, version]] ||= self.build(version, namespace)
        end

        # @returns [Array(String)] the versions which have been built so far.
        def built
          (@apis ||= {}).keys
        end

        # The classes which participate in versioning, which is to say those which include
        # {Versioned}. There is no registry to keep in step: a class opts in by including it.
        #
        # @returns [Hash] the unversioned classes, keyed by constant name.
        def classes(namespace)
          namespace.constants(false).each_with_object({}) do |name, classes|
            value = namespace.const_get(name)

            if value.is_a?(Class) and value.include?(Versioned)
              classes[name] = value
            end
          end
        end

        private

        def build(version, namespace)
          Module.new.tap do |api|
            api.const_set(:SPEC_VERSION, version)

            layers = self.layers_for(version)
            abstract = self.abstract_for(namespace)

            self.classes(namespace).each do |name, klass|
              api.const_set(name, self.derive(klass, name, version, layers, api, abstract))
            end

            # Anything which is not versioned - the wrapper, the errors, the paths - is shared, so
            # that `api::Whatever` resolves uniformly whether or not it is versioned:
            [namespace, Matrix].each do |source|
              source.constants(false).each do |name|
                value = source.const_get(name)

                if value.is_a?(Module) and !api.const_defined?(name, false)
                  api.const_set(name, value)
                end
              end
            end
          end
        end

        # The layers for a namespace: {Async::Matrix::ClientServer} is layered from
        # {Async::Matrix::Abstract::ClientServer}.
        #
        # @parameter namespace [Module] an API namespace.
        # @returns [Module | nil] the module holding that namespace's layers.
        def abstract_for(namespace)
          name = namespace.name.split("::").last.to_sym

          if Abstract.const_defined?(name, false)
            Abstract.const_get(name, false)
          end
        end

        # Derive a version of the given class, by including each applicable layer in order.
        #
        # `include` inserts each layer directly above the class, so the most recently included
        # layer is found first: layering in ascending order means a later version overrides an
        # earlier one, and `super` walks back down through the previous implementations and
        # finally into the unversioned class itself.
        def derive(klass, name, version, layers, api, abstract)
          Class.new(klass).tap do |derived|
            derived.const_set(:API, api)

            if abstract&.const_defined?(name, false)
              concept = abstract.const_get(name, false)

              layers.each do |layer_name|
                unless concept.const_defined?(layer_name, false)
                  next
                end

                layer = concept.const_get(layer_name, false)

                derived.include(layer)
                if layer.const_defined?(:ClassMethods, false)
                  derived.extend(layer::ClassMethods)
                end
              end
            end

            # An anonymous class has no name, which makes failures hard to read:
            label = "#{klass}[#{version.inspect}]"
            derived.define_singleton_method(:to_s){label}
            derived.define_singleton_method(:inspect){label}
          end
        end
      end
    end
  end
end
