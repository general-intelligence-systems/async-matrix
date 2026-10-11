# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Events
      module Readers
        def reads(field, bare: true)
          key = field.to_s

          names = [key, key.tr(".", "_")]

          if bare
            names << key.delete_prefix("m.")
          end

          names.uniq.each do |name|
            unless self.method_defined?(name)
              define_method(name){@value[key.to_sym]}
            end
          end
        end
      end
    end
  end
end
