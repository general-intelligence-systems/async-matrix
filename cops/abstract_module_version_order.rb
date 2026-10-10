# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "rubocop"

module RuboCop
  module Cop
    module AsyncMatrix
      # Checks that every layer container in `lib/async/matrix/abstract/` declares a module for
      # every supported specification version, and declares them from highest to lowest.
      #
      # A version layer is a module named after the version which introduced the behaviour, so
      # `v1.19` becomes `V1_19`. Declaring every version, including the ones which changed
      # nothing, means the set of layers can be read off the file rather than inferred from the
      # gaps: a missing module is then unambiguously a mistake rather than a deliberate no-op.
      #
      # The declaration order is for readers only. {Async::Matrix::Versions} applies layers in
      # ascending order regardless of where they appear in the file, because it looks them up by
      # name. Highest first puts the current behaviour at the top, where it is read first.
      #
      # @example
      #   # bad - V1_2 is missing, and the layers ascend
      #   module Abstract
      #     module Room
      #       module V1_1
      #       end
      #
      #       module V1_3
      #       end
      #     end
      #   end
      #
      #   # good - every version is present, highest first
      #   module Abstract
      #     module Room
      #       module V1_3
      #       end
      #
      #       # No changes in v1.2.
      #       module V1_2
      #       end
      #
      #       module V1_1
      #       end
      #     end
      #   end
      class AbstractModuleVersionOrder < Base
        MSG_MISSING = "Missing version %<layers>s. Declare every version, even as a no-op."

        MSG_UNKNOWN = "Unknown version %<layers>s, which is not one of the supported versions."

        MSG_ORDER = "Declare `%<layer>s` before `%<before>s`: order versions from highest (`%<highest>s`) to lowest (`%<lowest>s`)."

        # The versions which must be declared come from MATRIX_API_VERSIONS.txt, which is
        # generated from synapse/docker-compose.yml: the versions which can be tested are the
        # versions which must have a layer. Override the location with `VersionsPath`.
        DEFAULT_VERSIONS_PATH = File.expand_path("../MATRIX_API_VERSIONS.txt", __dir__)

        # @returns [String] where the list of versions is read from.
        def versions_path
          cop_config.fetch("VersionsPath", DEFAULT_VERSIONS_PATH)
        end

        # @returns [Array(String)] the versions which must be declared, oldest first.
        def versions
          @versions ||= begin
            path = self.versions_path

            unless File.exist?(path)
              raise "#{path} is missing: it is generated from synapse/docker-compose.yml."
            end

            versions = File.readlines(path, chomp: true).reject(&:empty?)

            if versions.empty?
              raise "#{path} is empty."
            end

            versions
          end
        end

        # @returns [Array(Symbol)] the expected layer names, highest first.
        def expected_layers
          @expected_layers ||= self.versions.map{|version| layer_name(version)}.reverse
        end

        def on_module(node)
          if self.abstract?(node)
            concepts = self.child_modules(node).flat_map{|namespace| self.child_modules(namespace)}
            concepts.each do |concept|
              layers = self.child_modules(concept).filter_map do |child|
                name = self.module_name(child)

                if name.to_s.start_with?("V")
                  [name, child]
                end
              end

              self.check_completeness(concept, layers)
              self.check_order(layers)
            end
          else
            nil
          end
        end

        private

        # `v1.19` -> `:V1_19`, mirroring `Async::Matrix::Versions.layer_name`.
        def layer_name(version)
          :"V#{version.to_s.delete_prefix("v").tr(".", "_")}"
        end

        def abstract?(node)
          self.module_name(node) == :Abstract
        end

        def module_name(node)
          node.identifier.short_name
        end

        # The modules declared directly inside the given module.
        def child_modules(node)
          body = node.body
          if body
            if body.begin_type?
              children = body.children
            else
              children = [body]
            end
            children.select{|child| child.is_a?(::RuboCop::AST::Node) && child.module_type?}
          else
            []
          end
        end

        def check_completeness(concept, layers)
          declared = layers.map(&:first)

          missing = self.expected_layers - declared
          unknown = declared - self.expected_layers

          if missing.any?
            add_offense(concept.identifier, message: format(MSG_MISSING, layers: self.describe(missing)))
          end

          unknown.each do |name|
            node = layers.assoc(name).last

            add_offense(node.identifier, message: format(MSG_UNKNOWN, layers: self.describe([name])))
          end
        end

        # Flag each point where the declarations stop descending, rather than every module
        # involved: a single swap is a single mistake.
        def check_order(layers)
          known = layers.select{|name, _| self.expected_layers.include?(name)}

          known.each_cons(2) do |(previous, _), (name, node)|
            if self.expected_layers.index(name) > self.expected_layers.index(previous)
              next
            end

            add_offense(node.identifier, message: format(MSG_ORDER,
              layer: name,
              before: previous,
              highest: self.expected_layers.first,
              lowest: self.expected_layers.last,
            ))
          end
        end

        def describe(names)
          if names.size == 1
            "layer `#{names.first}`"
          else
            "layers #{names.map{|name| "`#{name}`"}.join(", ")}"
          end
        end
      end
    end
  end
end
