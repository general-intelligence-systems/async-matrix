# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class GlobalProfile < Sequel::Model(:matrix_global_profiles)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :matrix_user_id
        validates_unique :matrix_user_id
      end

      def name
        if display_name.to_s.empty?
          matrix_user_id
        else
          display_name
        end
      end

      def localpart = matrix_user_id.to_s.sub(/\A@/, "").split(":").first
    end
  end
end

__END__

create_table?(:matrix_global_profiles) do
  primary_key :id, type: :Bignum, serial: true
  column      :matrix_user_id, TEXT, null: false
  column      :display_name, TEXT
  column      :avatar_url, TEXT
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :matrix_user_id, unique: true, name: :index_matrix_global_profiles_on_matrix_user_id
end
