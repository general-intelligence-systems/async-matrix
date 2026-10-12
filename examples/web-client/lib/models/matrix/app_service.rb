# frozen_string_literal: true

require "securerandom"
require "sequel/model"

require_relative "typecasting"
require "yaml"

module Models
  module Matrix
    class AppService < Sequel::Model(:matrix_app_services)
      TOKEN_BYTE_LENGTH = 32

      LOCALPART_RE = /\A[a-z0-9][a-z0-9._=\-\/]*\z/

      NATS_STREAM = "AGENT"

      one_to_many :namespaces,
        class: "Models::Matrix::AppServiceNamespace",
        key:   :matrix_app_service_id

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting
      # `accepts_nested_attributes_for :namespaces, allow_destroy: true`.
      plugin :nested_attributes
      nested_attributes :namespaces, destroy: true

      def self.router_url_base
        @router_url_base ||= ENV.fetch("MATRIX_APPSERVICE_URL_BASE")
      end

      def before_validation
        if new?
          generate_tokens
        end
        super
      end

      def validate
        super
        validates_presence %i[as_token hs_token]
        validates_unique :as_token
        validates_unique :hs_token
        validates_presence :sender_localpart
        validates_unique :sender_localpart
        validates_format LOCALPART_RE,
          :sender_localpart,
          message: "must be a valid Matrix localpart"
      end

      def registration_filename
        "#{sender_localpart}.yaml"
      end

      def registration_url
        "#{self.class.router_url_base}/#{uuid}"
      end

      def registration_yaml
        doc = {
          "id"               => uuid,
          "url"              => registration_url,
          "as_token"         => as_token,
          "hs_token"         => hs_token,
          "sender_localpart" => sender_localpart,
          "namespaces"       => registration_namespaces,
          "rate_limited"     => rate_limited,
        }
        doc["io.element.msc4190"] = true
        if receive_ephemeral
          doc["receive_ephemeral"] = true
        end
        doc.to_yaml
      end

      def registration_namespaces
        by_kind = namespaces.group_by(&:kind)
        AppServiceNamespace.kinds.keys.to_h do |kind|
          [kind, (by_kind[kind] || []).map { |ns| { "exclusive" => ns.exclusive, "regex" => ns.regex } }]
        end
      end

      def nats_durable
        "#{nats_token}_matrix"
      end

      def nats_token
        sender_localpart.to_s.gsub(/[^a-zA-Z0-9]+/, "_").downcase
      end

      def nats_inbox
        "agent.#{nats_token}.inbox.matrix"
      end

      def nats_outbox
        "agent.#{nats_token}.outbox.matrix"
      end

      private

        # The uuid is here rather than a column default because SQLite has no
        # gen_random_uuid() -- see the migration.
        def generate_tokens
          self.as_token ||= SecureRandom.hex(TOKEN_BYTE_LENGTH)
          self.hs_token ||= SecureRandom.hex(TOKEN_BYTE_LENGTH)
          self.uuid     ||= SecureRandom.uuid
        end
    end
  end
end

__END__

create_table?(:matrix_app_services) do
  primary_key :id, type: :Bignum, serial: true
  column      :as_token, TEXT, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :hs_token, TEXT, null: false
  column      :rate_limited, :boolean, default: false, null: false
  column      :receive_ephemeral, :boolean, default: true, null: false
  column      :sender_localpart, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false
  # Postgres had this as `uuid DEFAULT gen_random_uuid()`. SQLite has neither
  # the type nor the function, and the hex(randomblob(16)) trick that stands in
  # for it would put a uuid in the database that Ruby never sees -- so the
  # default moved into #before_validation beside the two tokens, which were
  # already minted there for the same reason.
  column      :uuid, TEXT, null: false

  index :as_token, unique: true, name: :index_matrix_app_services_on_as_token
  index :hs_token, unique: true, name: :index_matrix_app_services_on_hs_token
  index :sender_localpart,
    unique: true,
    name:   :index_matrix_app_services_on_sender_localpart
  index :uuid, unique: true, name: :index_matrix_app_services_on_uuid
end
