# frozen_string_literal: true

# /_matrix/client/v1/rooms/:roomId/*
# Covers: timestamp_to_event, relations, threads, hierarchy
module MatrixApi
  module Client
    module V1
      class Rooms < Base
        route_param :roomId, type: String, desc: 'The room ID' do

          # GET /rooms/:roomId/timestamp_to_event
          # Auth: yes | Rate-limited: yes | Added v1.6
          # Response: 200, 404, 429
          desc 'Get the closest event to a given timestamp.' do
            failure [
              [404, 'No event found'],
              [429, 'Rate limited']
            ]
          end
          params do
            requires :ts, type: Integer, desc: 'Timestamp in milliseconds (Unix epoch)'
            requires :dir, type: String, values: %w[b f], desc: 'Direction to search'
          end
          get :timestamp_to_event do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # =================================================================
          # Relations
          # =================================================================
          namespace :relations do
            route_param :eventId, type: String, desc: 'The parent event ID' do

              # GET /rooms/:roomId/relations/:eventId
              # Auth: yes | Rate-limited: no | Added v1.3 | Response: 200
              desc 'Get events related to a given event.'
              params do
                optional :from, type: String, desc: 'Pagination token'
                optional :to, type: String, desc: 'Pagination token'
                optional :limit, type: Integer, desc: 'Max results'
                optional :dir, type: String, values: %w[b f], desc: 'Direction'
                optional :recurse, type: Boolean, desc: 'Recurse into child relations (added v1.12)'
              end
              get do
                authenticate!
                # TODO: implement
                status 200
              end

              route_param :relType, type: String, desc: 'The relationship type' do

                # GET /rooms/:roomId/relations/:eventId/:relType
                # Response: 200
                desc 'Get related events filtered by relation type.'
                params do
                  optional :from, type: String
                  optional :to, type: String
                  optional :limit, type: Integer
                  optional :dir, type: String, values: %w[b f]
                  optional :recurse, type: Boolean
                end
                get do
                  authenticate!
                  # TODO: implement
                  status 200
                end

                route_param :eventType, type: String, desc: 'The event type to filter' do

                  # GET /rooms/:roomId/relations/:eventId/:relType/:eventType
                  # Response: 200
                  desc 'Get related events filtered by relation type and event type.'
                  params do
                    optional :from, type: String
                    optional :to, type: String
                    optional :limit, type: Integer
                    optional :dir, type: String, values: %w[b f]
                    optional :recurse, type: Boolean
                  end
                  get do
                    authenticate!
                    # TODO: implement
                    status 200
                  end
                end
              end
            end
          end

          # =================================================================
          # Threads
          # =================================================================

          # GET /rooms/:roomId/threads
          # Auth: yes | Rate-limited: yes | Added v1.4
          # Response: 200, 400, 403, 429
          desc 'Get threads in a room.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden'],
              [429, 'Rate limited']
            ]
          end
          params do
            optional :include, type: String, values: %w[all participated], desc: 'Thread filter'
            optional :limit, type: Integer, desc: 'Max results'
            optional :from, type: String, desc: 'Pagination token'
          end
          get :threads do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # =================================================================
          # Hierarchy (Spaces)
          # =================================================================

          # GET /rooms/:roomId/hierarchy
          # Auth: yes | Rate-limited: yes | Added v1.2
          # Response: 200, 400, 403, 429
          desc 'Get the space hierarchy for a room.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden'],
              [429, 'Rate limited']
            ]
          end
          params do
            optional :suggested_only, type: Boolean, desc: 'Only return suggested rooms'
            optional :limit, type: Integer, desc: 'Max rooms per response'
            optional :max_depth, type: Integer, desc: 'Max depth to traverse'
            optional :from, type: String, desc: 'Pagination token'
          end
          get :hierarchy do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

        end # route_param :roomId
      end
    end
  end
end
