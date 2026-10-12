# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # The media cache: the bytes behind an mxc:// URI.
    #
    # matrix-sdk-sqlite gives this a DATABASE OF ITS OWN -- the media store, in
    # the cache directory rather than the data directory, so that clearing a
    # cache cannot lose anything that is not refetchable. Here it is a table in
    # the one file, which is the single place this departs from that layout; the
    # reason it is still worth separating in the SDK is the reason `ignore_policy`
    # exists below.
    #
    # KEYED ON (uri, format), NOT uri. One mxc:// URI has a full-size file and a
    # thumbnail per requested size, and they are different rows: `format` is the
    # thumbnail spec, or the marker for the original.
    class Media < Sequel::Model(:matrix_media)
      # `format` for the unmodified file, as opposed to a thumbnail of it.
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

        # What a cache eviction pass may remove, oldest first. Rows the policy
        # is ignored for are not in it -- see #retain?.
        def evictable = where(ignore_policy: false).order(:last_access)
      end

      # Whether the cache retention policy leaves this row alone. Set for media
      # the user has deliberately kept, which is why the policy is a per-row
      # flag rather than a sweep over everything.
      def retain? = !!ignore_policy

      # Reading a cached file is what keeps it cached, so the read records
      # itself. Milliseconds, like every other timestamp the homeserver speaks.
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
