# frozen_string_literal: true

# /_matrix/client/v3/pushrules/*
module MatrixApi
  module Client
    module V3
      class Pushrules < Base
        # GET /pushrules/ - all push rules
        # Auth: yes | Rate-limited: no | Response: 200
        desc 'Get all push rules for the user.'
        get do
          authenticate!
          # TODO: implement
          status 200
        end

        namespace :global do
          # GET /pushrules/global/
          # Auth: yes | Rate-limited: no | Response: 200
          desc 'Get all global push rules.'
          get do
            authenticate!
            # TODO: implement
            status 200
          end

          route_param :kind, type: String, values: %w[override underride sender room content], desc: 'The kind of rule' do
            route_param :ruleId, type: String, desc: 'The rule identifier' do

              # GET /pushrules/global/:kind/:ruleId
              # Response: 200, 404
              desc 'Get a specific push rule.' do
                failure [[404, 'Not found']]
              end
              get do
                authenticate!
                # TODO: implement
                status 200
              end

              # PUT /pushrules/global/:kind/:ruleId
              # Rate-limited: yes | Response: 200, 400, 404, 429
              desc 'Set a push rule.' do
                failure [
                  [400, 'Bad request'],
                  [404, 'Not found'],
                  [429, 'Rate limited']
                ]
              end
              params do
                optional :before, type: String, desc: 'Position before this rule'
                optional :after, type: String, desc: 'Position after this rule'
                requires :actions, type: Array, desc: 'Actions to perform'
                optional :conditions, type: Array, desc: 'Conditions (override/underride)'
                optional :pattern, type: String, desc: 'Pattern (content rules)'
              end
              put do
                authenticate!
                rate_limit!
                # TODO: implement
                status 200
              end

              # DELETE /pushrules/global/:kind/:ruleId
              # Response: 200, 404
              desc 'Delete a push rule.' do
                failure [[404, 'Not found']]
              end
              delete do
                authenticate!
                # TODO: implement
                status 200
              end

              # GET/PUT /pushrules/global/:kind/:ruleId/actions
              namespace :actions do
                desc 'Get the actions for a push rule.' do
                  failure [[404, 'Not found']]
                end
                get do
                  authenticate!
                  # TODO: implement
                  status 200
                end

                desc 'Set the actions for a push rule.' do
                  failure [[404, 'Not found'], [429, 'Rate limited']]
                end
                params do
                  requires :actions, type: Array, desc: 'The actions to set'
                end
                put do
                  authenticate!
                  rate_limit!
                  # TODO: implement
                  status 200
                end
              end

              # GET/PUT /pushrules/global/:kind/:ruleId/enabled
              namespace :enabled do
                desc 'Get whether a push rule is enabled.' do
                  failure [[404, 'Not found']]
                end
                get do
                  authenticate!
                  # TODO: implement
                  status 200
                end

                desc 'Enable or disable a push rule.' do
                  failure [[404, 'Not found'], [429, 'Rate limited']]
                end
                params do
                  requires :enabled, type: Boolean, desc: 'Whether the rule is enabled'
                end
                put do
                  authenticate!
                  rate_limit!
                  # TODO: implement
                  status 200
                end
              end

            end
          end
        end
      end
    end
  end
end
