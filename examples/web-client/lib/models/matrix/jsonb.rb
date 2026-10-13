# frozen_string_literal: true

require "json"
require "sequel/model"

module Models
  module Matrix
    module JSONB
      def jsonb(*names)
        plugin :serialization

        set_dataset(
          dataset.select(
            *columns.map do |column|
              if names.include?(column)
                Sequel.function(:json, column).as(column)
              else
                column
              end
            end,
          ),
        )

        names.each do |name|
          serialize_attributes([SERIALIZER, DESERIALIZER], name)
        end
      end

      SERIALIZER = lambda do |value|
        if value.nil?
          nil
        else
          Sequel.function(:jsonb, JSON.generate(value))
        end
      end

      DESERIALIZER = lambda do |value|
        if value.nil?
          nil
        else
          JSON.parse(value)
        end
      end
    end
  end
end
