# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "yaml"

require_relative "support/prism_source"

module RuboCop
  module Cop
    module AsyncMatrix
      # Checks that a version whose deltas say it changed carries code in its layer.
      #
      # The earliest version is excused, since the base class carries what every version has.
      #
      # @example
      #   # bad - rooms-v1.12.deltas.yaml says v1.12 changed
      #   # No changes in v1.12.
      #   module V1_12
      #   end
      #
      # @example
      #   # good
      #   # v1.12 added the capability.
      #   module V1_12
      #     def set_displayname?
      #       true
      #     end
      #   end
      class AbstractModuleDeltaHasCode < Base
        include PrismSource

        MSG = "%<version>s changed, so this layer must carry what changed: see `%<deltas>s`."

        # The versions come from MATRIX_API_VERSIONS.txt, as they do for the other layer cops. Override the location with `VersionsPath`.
        DEFAULT_VERSIONS_PATH = File.expand_path("../MATRIX_API_VERSIONS.txt", __dir__)

        # @returns [String] where the list of versions is read from.
        def versions_path
          cop_config.fetch("VersionsPath", DEFAULT_VERSIONS_PATH)
        end

        # @returns [Array(String)] the versions, oldest first.
        def versions
          @versions ||= File.readlines(self.versions_path, chomp: true).reject(&:empty?)
        end

        def on_new_investigation
          path = processed_source.file_path

          if path and schemas = self.schemas_for(path)
            stem = self.stem_for(path, schemas)

            if stem
              self.check_layers(schemas, stem)
            else
              nil
            end
          else
            nil
          end
        end

        private

        # The schemas beside a layer file, which for a test are the ones beside the file it mirrors.
        #
        # @returns [String | nil] the directory, or nil where there is none.
        def schemas_for(path)
          absolute = File.expand_path(path)
          segments = absolute.split(File::SEPARATOR)
          index = segments.rindex("test")

          if index
            segments[index] = "lib"
            absolute = File.join(segments)
          end

          schemas = File.join(File.dirname(absolute), "schemas")

          if File.directory?(schemas)
            schemas
          end
        end

        # The specification's own name for this concept, which a Ruby file cannot always spell.
        #
        # The schemas are matched forwards, since `call_answer` cannot say where `m.call.answer` put its dots.
        #
        # @returns [String | nil] the schema name, or nil where no schema names this file.
        def stem_for(path, schemas)
          wanted = File.basename(path, ".rb")

          Dir.glob(File.join(schemas, "*.deltas.yaml")).lazy.map do |candidate|
            File.basename(candidate).sub(/-v\d+\.\d+\.deltas\.yaml\z/, "")
          end.find{|stem| self.ruby_name(stem) == wanted}
        end

        # `m.room.message` -> `room_message`, as the layer files are named.
        def ruby_name(stem)
          stem.delete_prefix("m.").tr(".-", "__")
        end

        def check_layers(schemas, stem)
          layers = self.layers_in(self.prism_each(::Prism::ModuleNode))

          # The earliest version introduces the operations, which the base class carries:
          self.versions.drop(1).each do |version|
            deltas = File.join(schemas, "#{stem}-#{version}.deltas.yaml")

            unless File.exist?(deltas) and self.changed?(deltas)
              next
            end

            node = layers[self.layer_name(version)]

            if node.nil? or node.body
              nil
            else
              add_offense(self.prism_node_range(node.constant_path), message: format(MSG,
                version: version,
                deltas: self.readable(deltas),
              ))
            end
          end
        end

        # @returns [Boolean] whether the deltas say that version changed something.
        def changed?(deltas)
          YAML.safe_load_file(deltas)["changed"] == true
        end

        # The version layers in this file, by name, which are the ones written below `Abstract`.
        #
        # @returns [Hash] the layers, keyed by constant name.
        def layers_in(nodes)
          nodes.each_with_object({}) do |node, layers|
            if /\AV\d+_\d+\z/.match?(node.name.to_s) and self.abstract?(node)
              layers[node.name] = node
            end
          end
        end

        def abstract?(node)
          self.prism_ancestors(node).any? do |ancestor|
            ancestor.is_a?(::Prism::ModuleNode) && ancestor.name == :Abstract
          end
        end

        # `v1.19` -> `:V1_19`, mirroring {ruby Async::Matrix::Versions.layer_name}.
        def layer_name(version)
          :"V#{version.delete_prefix("v").tr(".", "_")}"
        end

        # The deltas file relative to the project, since an absolute path in a message is noise.
        def readable(deltas)
          deltas.sub(%r{\A.*?(?=lib/)}, "")
        end
      end
    end
  end
end
