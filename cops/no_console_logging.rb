# frozen_string_literal: true

# Bans logging straight at the `Console` singleton (the socketry `console` gem):
#
#   Console.info(self, "started", id: 1)          # NO
#   Console.logger.warn(self, "slow")             # NO
#   Console.debug(self) { "expensive" }           # NO
#
#   Rails.logger.info("started")                  # YES
#
# Everything must log through `Rails.logger`, which console-adapter-rails
# (https://github.com/socketry/console-adapter-rails) replaces with a
# Console::Adapter::Rails::Logger at boot — a Console::Compatible::Logger wrapped
# in ActiveSupport::TaggedLogging. So `Rails.logger` IS Console; the output ends
# up in the same place either way.
#
# What the direct call skips is everything the adapter's logger adds on the way
# through: `Rails.logger.tagged` tags (which the adapter unwraps into structured
# fields), `silence` / `local_level` — which is fiber-local in the adapter, so it
# works under falcon — and per-environment logger configuration. Code calling
# Console directly cannot be silenced or tagged by its caller.
#
# The adapter's own log subscribers (ActionController / ActiveRecord) do call
# `Console.logger.info` — that is the gem's job, on the far side of this
# boundary, and the gem is not this repo.
module RuboCop
  module Cop
    module Local
      class NoConsoleLogging < Base
        MSG = "Do not log through `Console` directly; use `Rails.logger.%<level>s` " \
              "so logging goes through Console::Adapter::Rails (tags, silencing, config)."

        MSG_LOGGER = "Do not reach for `Console.logger`; use `Rails.logger`, which " \
                     "console-adapter-rails already backs with Console."

        # Console's severity methods, plus `call`, its lowest-level entry point.
        LEVELS = %i[debug info warn error fatal call].freeze

        def on_send(node)
          if console_logger?(node)
            add_offense(node, message: MSG_LOGGER)
          elsif LEVELS.include?(node.method_name) && console_receiver?(node.receiver)
            add_offense(node, message: format(MSG, level: node.method_name))
          end
        end

        private

          # `Console.logger`, but NOT the `Console.logger` inside a
          # `Console.logger.info(...)` — that whole call is reported once, as a
          # level offence, rather than twice.
          def console_logger?(node)
            node.method_name == :logger &&
              const_console?(node.receiver) &&
              !level_call_on?(node)
          end

          # Is `node` the receiver of a level call, i.e. the `Console.logger` in
          # `Console.logger.info(...)`?
          def level_call_on?(node)
            parent = node.parent

            parent&.send_type? && parent.receiver.equal?(node) && LEVELS.include?(parent.method_name)
          end

          # The receiver of a level call: `Console` itself or `Console.logger`.
          def console_receiver?(receiver)
            const_console?(receiver) ||
              (receiver&.send_type? && receiver.method_name == :logger && const_console?(receiver.receiver))
          end

          # `Console` or `::Console` — and nothing nested, so a `Foo::Console`
          # of your own is left alone.
          def const_console?(node)
            node&.const_type? && node.short_name == :Console && (node.namespace.nil? || node.namespace.cbase_type?)
          end
      end
    end
  end
end
