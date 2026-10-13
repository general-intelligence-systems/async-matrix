# frozen_string_literal: true

require "securerandom"
require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class Credential < Sequel::Model(:matrix_credentials)
      DEVICE_ID_LENGTH = 10

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      plugin :column_encryption do |enc|
        enc.key 0, ENV.fetch("MATRIX_ENCRYPTION_KEY")

        enc.column :access_token
        enc.column :refresh_token
      end

      def validate
        super
        validates_presence :device_id
        validates_presence :homeserver_url
        validates_presence :matrix_user_id
      end

      def self.generate_device_id
        SecureRandom.alphanumeric(DEVICE_ID_LENGTH)
      end

      def self.for(homeserver_url)
        record = first
        if record && record.homeserver_url == homeserver_url
          record
        end
      end

      def expired?(skew_ms = 0)
        if expires_at.nil?
          false
        else
          expires_at - skew_ms <= (Time.now.to_f * 1000).to_i
        end
      end

      def usable?
        !access_token.to_s.empty? && !matrix_user_id.to_s.empty?
      end
    end
  end
end

__END__

create_table?(:matrix_credentials) do
  primary_key :id, type: :Bignum, serial: true
  column      :access_token, :text
  column      :created_at, TIMESTAMP, null: false
  column      :device_id, TEXT, null: false
  # The OAuth client id this session registered as, which Fractal keeps in the
  # same keyring item as the rest of these.
  column      :client_id, TEXT
  column      :expires_at, :bigint
  column      :homeserver_url, TEXT, null: false
  column      :matrix_user_id, TEXT
  column      :refresh_token, :text
  column      :updated_at, TIMESTAMP, null: false


end
