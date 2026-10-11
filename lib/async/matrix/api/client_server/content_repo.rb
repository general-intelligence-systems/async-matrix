# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../content"
require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/content_repo"

module Async
  module Matrix
    module ClientServer
      # The file an upload created.
      #
      # The bytes went up as they were, so the answer is read by {Uploaded} rather than {Representation}.
      class UploadedContent < Uploaded
        include Versioned

        # @returns [String] the `mxc://` URI the file is at.
        def content_uri
          self.value[:content_uri]
        end
      end

      # The file a creation reserved, which an upload fills in.
      #
      # The endpoint arrived in v1.7, so the fields are read by that layer.
      class CreatedContent < Representation
        include Versioned
      end

      # What a homeserver will accept.
      class MediaConfig < Representation
        include Versioned

        # @returns [Integer | nil] the largest file it will take, in bytes.
        def upload_size
          self.value[:"m.upload.size"]
        end
      end

      # What a homeserver found at a URL.
      class UrlPreview < Representation
        include Versioned

        # @returns [String | nil] the `mxc://` URI of the image, where the page had one.
        def og_image
          self.value[:"og:image"]
        end

        # @returns [Integer | nil] how large that image is, in bytes.
        def image_size
          self.value[:"matrix:image:size"]
        end
      end

      # The files a homeserver holds.
      class ContentRepo
        include Versioned

        # @returns [String] the path files are uploaded to.
        def self.path
          "#{MEDIA_V3}/upload"
        end

        # @parameter kind [String] `download` or `thumbnail`.
        # @parameter server_name [String] the homeserver which holds the file.
        # @parameter media_id [String] the file itself.
        # @returns [String] the path of that file.
        def self.path_for(kind, server_name, media_id)
          parts = [server_name, media_id].map{|part| ::Protocol::URL::Encoding.escape(part)}

          "#{MEDIA_V3}/#{kind}/#{parts.join("/")}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ContentRepo] the repository.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Upload a file.
        #
        # @parameter content [String] the bytes to upload.
        # @parameter content_type [String] what the bytes are, e.g. `text/plain`.
        # @parameter filename [String | nil] the name to give the file.
        # @returns [UploadedContent] the `mxc://` URI it was uploaded to.
        def upload_content(content, content_type, filename: nil)
          parameters = {filename: filename}.compact
          resource = @resource.with(path: self.class.path, parameters: parameters, headers: {"content-type" => content_type})

          api::UploadedContent.post(resource, content)
        end

        # A file, by the server and the ID its `mxc://` URI names.
        #
        # @parameter server_name [String] the homeserver which holds the file.
        # @parameter media_id [String] the file itself.
        # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
        # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
        # @returns [Content] the bytes, where no block is given.
        def get_content(server_name, media_id, allow_remote: nil, &block)
          parameters = {allow_remote: allow_remote}.compact

          api::Content.get(@resource.with(path: self.class.path_for("download", server_name, media_id), parameters: parameters), &block)
        end

        # A file, under a name of the caller's choosing.
        #
        # @parameter server_name [String] the homeserver which holds the file.
        # @parameter media_id [String] the file itself.
        # @parameter file_name [String] the name to ask for it under.
        # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
        # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
        # @returns [Content] the bytes, where no block is given.
        def get_content_override_name(server_name, media_id, file_name, allow_remote: nil, &block)
          parameters = {allow_remote: allow_remote}.compact
          path = "#{self.class.path_for("download", server_name, media_id)}/#{::Protocol::URL::Encoding.escape(file_name)}"

          api::Content.get(@resource.with(path: path, parameters: parameters), &block)
        end

        # A thumbnail of a file.
        #
        # @parameter server_name [String] the homeserver which holds the file.
        # @parameter media_id [String] the file itself.
        # @parameter width [Integer] the width wanted, in pixels.
        # @parameter height [Integer] the height wanted, in pixels.
        # @parameter method [String | nil] `crop` or `scale`.
        # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
        # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
        # @returns [Content] the bytes of the thumbnail, where no block is given.
        def get_content_thumbnail(server_name, media_id, width, height, method: nil, allow_remote: nil, &block)
          parameters = {width: width, height: height, method: method, allow_remote: allow_remote}.compact

          api::Content.get(@resource.with(path: self.class.path_for("thumbnail", server_name, media_id), parameters: parameters), &block)
        end

        # What this homeserver will accept.
        #
        # @returns [MediaConfig] the limits it sets.
        def get_config
          api::MediaConfig.get(@resource.with(path: "#{MEDIA_V3}/config"))
        end

        # What the homeserver finds at a URL, so that a client can show it.
        #
        # @parameter url [String] the page to look at.
        # @parameter ts [Integer | nil] the moment to look at it as of, in milliseconds.
        # @returns [UrlPreview] what it found.
        def get_url_preview(url, ts: nil)
          parameters = {url: url, ts: ts}.compact

          api::UrlPreview.get(@resource.with(path: "#{MEDIA_V3}/preview_url", parameters: parameters))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
