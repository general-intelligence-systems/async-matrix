# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::ContentRepo}.
        module ContentRepo
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # No changes in v1.16.
          module V1_16
          end

          # No changes in v1.15.
          module V1_15
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # No changes in v1.12.
          module V1_12
          end

          # No changes in v1.11.
          module V1_11
          end

          # No changes in v1.10.
          module V1_10
          end

          # No changes in v1.9.
          module V1_9
          end

          # No changes in v1.8.
          module V1_8
          end

          # v1.7 added reserving a URI before the bytes are ready.
          module V1_7
            # Reserve a `mxc://` URI, which an upload fills in later.
            #
            # @returns [CreatedContent] the URI, and how long it is held.
            def create_content
              api::CreatedContent.post(@resource.with(path: "#{MEDIA_V1}/create"), {})
            end

            # Upload the bytes of a URI which was reserved.
            #
            # @parameter server_name [String] the homeserver which reserved it.
            # @parameter media_id [String] the URI reserved.
            # @parameter content [String] the bytes to upload.
            # @parameter content_type [String] what the bytes are, e.g. `text/plain`.
            # @parameter filename [String | nil] the name to give the file.
            # @returns [Representation] the empty response.
            def upload_content_to_mxc(server_name, media_id, content, content_type, filename: nil)
              parameters = {filename: filename}.compact
              parts = [server_name, media_id].map{|part| ::Protocol::URL::Encoding.escape(part)}
              resource = @resource.with(path: "#{self.class.path}/#{parts.join("/")}", parameters: parameters, headers: {"content-type" => content_type})

              api::Uploaded.put(resource, content)
            end
          end

          # No changes in v1.6.
          module V1_6
          end

          # No changes in v1.5.
          module V1_5
          end

          # No changes in v1.4.
          module V1_4
          end

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ClientServer::CreatedContent}.
        module CreatedContent
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # No changes in v1.16.
          module V1_16
          end

          # No changes in v1.15.
          module V1_15
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # No changes in v1.12.
          module V1_12
          end

          # No changes in v1.11.
          module V1_11
          end

          # No changes in v1.10.
          module V1_10
          end

          # No changes in v1.9.
          module V1_9
          end

          # No changes in v1.8.
          module V1_8
          end

          # v1.7 added the reservation, which names the URI it held.
          module V1_7
            # @returns [String] the `mxc://` URI which was reserved.
            def content_uri
              self.value[:content_uri]
            end

            # @returns [Integer | nil] when the reservation lapses, in milliseconds since the epoch.
            def unused_expires_at
              self.value[:unused_expires_at]
            end
          end

          # No changes in v1.6.
          module V1_6
          end

          # No changes in v1.5.
          module V1_5
          end

          # No changes in v1.4.
          module V1_4
          end

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
