# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::PushRules}.
        module PushRules
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

          # v1.12 hardcoded `global` and dropped `scope` from the path.
          module V1_12
            module ClassMethods
              # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
              # @parameter rule_id [String] the rule itself.
              # @returns [String] the path of that rule.
              def path_for(kind, rule_id)
                parts = [kind, rule_id].map{|part| ::Protocol::URL::Encoding.escape(part)}

                "#{V3}/pushrules/global/#{parts.join("/")}"
              end
            end

            # The rules of the global scope, which is every rule a user has.
            #
            # @returns [GlobalRuleset] the rules, by kind.
            def get_push_rules_global
              api::GlobalRuleset.get(@resource.with(path: "#{self.class.path}global/"))
            end

            # One rule.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to read.
            # @returns [PushRule] the rule.
            def get_push_rule(kind, rule_id)
              api::PushRule.get(@resource.with(path: self.class.path_for(kind, rule_id)))
            end

            # Add a rule, or replace one.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to add or replace.
            # @parameter actions [Array] what to do when it matches, e.g. `notify`.
            # @parameter before [String | nil] the rule to put this one before.
            # @parameter after [String | nil] the rule to put this one after.
            # @parameter payload [Hash] the rest the kind takes, e.g. `conditions:`, `pattern:`.
            # @returns [Representation] the empty response.
            def set_push_rule(kind, rule_id, actions, before: nil, after: nil, **payload)
              parameters = {before: before, after: after}.compact

              api::Representation.put(@resource.with(path: self.class.path_for(kind, rule_id), parameters: parameters), {actions: actions, **payload})
            end

            # Remove a rule.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to remove.
            # @returns [Representation] the empty response.
            def delete_push_rule(kind, rule_id)
              api::Representation.delete(@resource.with(path: self.class.path_for(kind, rule_id)))
            end

            # What one rule does when it matches.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to read.
            # @returns [RuleActions] the actions.
            def get_push_rule_actions(kind, rule_id)
              api::RuleActions.get(@resource.with(path: "#{self.class.path_for(kind, rule_id)}/actions"))
            end

            # Set what one rule does when it matches.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to set.
            # @parameter actions [Array] the actions, e.g. `notify`.
            # @returns [Representation] the empty response.
            def set_push_rule_actions(kind, rule_id, actions)
              api::Representation.put(@resource.with(path: "#{self.class.path_for(kind, rule_id)}/actions"), {actions: actions})
            end

            # Whether one rule is being applied.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to read.
            # @returns [RuleEnabled] whether it is.
            def is_push_rule_enabled(kind, rule_id)
              api::RuleEnabled.get(@resource.with(path: "#{self.class.path_for(kind, rule_id)}/enabled"))
            end

            # Apply one rule, or stop applying it.
            #
            # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
            # @parameter rule_id [String] the rule to enable or disable.
            # @parameter enabled [Boolean] whether to apply it.
            # @returns [Representation] the empty response.
            def set_push_rule_enabled(kind, rule_id, enabled)
              api::Representation.put(@resource.with(path: "#{self.class.path_for(kind, rule_id)}/enabled"), {enabled: enabled})
            end
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

          # No changes in v1.7.
          module V1_7
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

        # Layers for {ruby Async::Matrix::ClientServer::GlobalRuleset}.
        module GlobalRuleset
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

          # v1.12 added the scope, which carries a list per kind.
          module V1_12
            # @returns [Array(Hash)] the rules which match on the content of an event.
            def content
              self.value[:content] || []
            end

            # @returns [Array(Hash)] the rules which are applied before the rest.
            def override
              self.value[:override] || []
            end

            # @returns [Array(Hash)] the rules which match on a room.
            def room
              self.value[:room] || []
            end

            # @returns [Array(Hash)] the rules which match on a sender.
            def sender
              self.value[:sender] || []
            end

            # @returns [Array(Hash)] the rules which are applied after the rest.
            def underride
              self.value[:underride] || []
            end
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

          # No changes in v1.7.
          module V1_7
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
