# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/pushrules"

module Async
  module Matrix
    module ClientServer
      # Every rule a user has, by the scope they are in.
      class PushRuleset < Representation
        include Versioned

        # @returns [Hash] the rules of the global scope, by kind.
        def global
          self.value[:global] || {}
        end
      end

      # The rules of the global scope.
      #
      # The endpoint arrived in v1.12, so the kinds are read by that layer.
      class GlobalRuleset < Representation
        include Versioned
      end

      # One rule.
      class PushRule < Representation
        include Versioned

        # @returns [String] the rule, by ID.
        def rule_id
          self.value[:rule_id]
        end

        # @returns [Array] what to do when the rule matches, e.g. `notify`.
        def actions
          self.value[:actions] || []
        end

        # @returns [Array(Hash) | nil] what the rule matches on, where its kind has conditions.
        def conditions
          self.value[:conditions]
        end

        # @returns [String | nil] the pattern the rule matches, where its kind has one.
        def pattern
          self.value[:pattern]
        end

        # @returns [Boolean] whether the homeserver made the rule rather than the user.
        def default?
          self.value[:default]
        end

        # @returns [Boolean] whether the rule is being applied.
        def enabled?
          self.value[:enabled]
        end
      end

      # What one rule does when it matches.
      class RuleActions < Representation
        include Versioned

        # @returns [Array] the actions, e.g. `notify`.
        def actions
          self.value[:actions] || []
        end
      end

      # Whether one rule is being applied.
      class RuleEnabled < Representation
        include Versioned

        # @returns [Boolean] whether it is.
        def enabled?
          self.value[:enabled]
        end
      end

      # The rules which decide what raises a notification.
      class PushRules
        include Versioned

        # @returns [String] the path of every rule.
        def self.path
          "#{V3}/pushrules/"
        end

        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule itself.
        # @returns [String] the path of that rule.
        def self.path_for(scope, kind, rule_id)
          parts = [scope, kind, rule_id].map{|part| ::Protocol::URL::Encoding.escape(part)}

          "#{V3}/pushrules/#{parts.join("/")}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PushRules] the rules.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Every rule this user has.
        #
        # @returns [PushRuleset] the rules, by scope.
        def get_push_rules
          api::PushRuleset.get(@resource.with(path: self.class.path))
        end

        # One rule.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to read.
        # @returns [PushRule] the rule.
        def get_push_rule(scope, kind, rule_id)
          api::PushRule.get(@resource.with(path: self.class.path_for(scope, kind, rule_id)))
        end

        # Add a rule, or replace one.
        #
        # @parameter scope [String] the scope to add it to, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to add or replace.
        # @parameter actions [Array] what to do when it matches, e.g. `notify`.
        # @parameter before [String | nil] the rule to put this one before.
        # @parameter after [String | nil] the rule to put this one after.
        # @parameter payload [Hash] the rest the kind takes, e.g. `conditions:`, `pattern:`.
        # @returns [Representation] the empty response.
        def set_push_rule(scope, kind, rule_id, actions, before: nil, after: nil, **payload)
          parameters = {before: before, after: after}.compact

          api::Representation.put(@resource.with(path: self.class.path_for(scope, kind, rule_id), parameters: parameters), {actions: actions, **payload})
        end

        # Remove a rule.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to remove.
        # @returns [Representation] the empty response.
        def delete_push_rule(scope, kind, rule_id)
          api::Representation.delete(@resource.with(path: self.class.path_for(scope, kind, rule_id)))
        end

        # What one rule does when it matches.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to read.
        # @returns [RuleActions] the actions.
        def get_push_rule_actions(scope, kind, rule_id)
          api::RuleActions.get(@resource.with(path: "#{self.class.path_for(scope, kind, rule_id)}/actions"))
        end

        # Set what one rule does when it matches.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to set.
        # @parameter actions [Array] the actions, e.g. `notify`.
        # @returns [Representation] the empty response.
        def set_push_rule_actions(scope, kind, rule_id, actions)
          api::Representation.put(@resource.with(path: "#{self.class.path_for(scope, kind, rule_id)}/actions"), {actions: actions})
        end

        # Whether one rule is being applied.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to read.
        # @returns [RuleEnabled] whether it is.
        def is_push_rule_enabled(scope, kind, rule_id)
          api::RuleEnabled.get(@resource.with(path: "#{self.class.path_for(scope, kind, rule_id)}/enabled"))
        end

        # Apply one rule, or stop applying it.
        #
        # @parameter scope [String] the scope the rule is in, which is `global`.
        # @parameter kind [String] the kind of rule, e.g. `override` or `room`.
        # @parameter rule_id [String] the rule to enable or disable.
        # @parameter enabled [Boolean] whether to apply it.
        # @returns [Representation] the empty response.
        def set_push_rule_enabled(scope, kind, rule_id, enabled)
          api::Representation.put(@resource.with(path: "#{self.class.path_for(scope, kind, rule_id)}/enabled"), {enabled: enabled})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
