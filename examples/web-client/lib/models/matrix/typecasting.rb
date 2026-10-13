# frozen_string_literal: true

require "sequel/model"

module Models
  module Matrix
    module Typecasting
      TYPES = %i[boolean date datetime time].freeze

      def self.extended(model)
        columns = model.db.schema(model.table_name).filter_map do |column, info|
          if TYPES.include?(info[:type])
            column
          end
        end

        model.plugin :typecast_on_load, *columns
        model.plugin :defaults_setter
      end
    end
  end
end
