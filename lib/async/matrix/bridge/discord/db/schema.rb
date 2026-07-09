# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "sequel"

# Sequel::Model requires a database connection at subclass definition time.
# Set a placeholder in-memory SQLite so models can be defined at load time.
# The real database is bound later via DB.connect / DB.bind_models.
#
# require_valid_table = false suppresses the column introspection that Sequel
# normally does on inheritance — critical because the placeholder DB has no
# tables.
unless Sequel::Model.instance_variable_get(:@db)
  Sequel::Model.db = Sequel.sqlite
  Sequel::Model.require_valid_table = false
end
