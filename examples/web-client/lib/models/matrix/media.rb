# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class Media < Sequel::Model(:matrix_media)
      FILE = "file"

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[uri format]
        validates_unique %i[uri format]
      end

      dataset_module do
        def for_uri(uri) = where(uri: uri)

        def evictable = where(ignore_policy: false).order(:last_access)
      end

      def retain? = !!ignore_policy

      def touch!
        update(last_access: (Time.now.to_f * 1000).to_i)
      end

      def self.fetch(uri:, format: FILE)
        first(uri: uri, format: format)&.tap(&:touch!)
      end

      def self.store!(uri:, data:, format: FILE, ignore_policy: false)
        row = first(uri: uri, format: format) || new(uri: uri, format: format)
        row.set(
          data:          Sequel.blob(data),
          last_access:   (Time.now.to_f * 1000).to_i,
          ignore_policy: ignore_policy,
        )
        row.save
      end
    end
  end
end

__END__

create_table?(:matrix_media) do
  primary_key :id, type: :Bignum, serial: true
  column      :uri, TEXT, null: false
  # The thumbnail spec, or "file" for the original -- see the class comment.
  column      :format, TEXT, default: "file", null: false
  # THE ACTUAL BYTES, and the one blob column here that is not JSONB. Nothing
  # in Models::Matrix::JSONB touches it: it is an image, not a document.
  column      :data, :blob, null: false
  # Milliseconds. Written on every read, which is what makes an eviction pass
  # possible at all.
  column      :last_access, :bigint, null: false
  column      :ignore_policy, :boolean, default: false, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[uri format], unique: true, name: :index_matrix_media_on_uri_and_format
  index :last_access, name: :index_matrix_media_on_last_access
end
