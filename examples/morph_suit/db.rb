# frozen_string_literal: true

require 'sequel'

# Connect to the Matrix/Synapse PostgreSQL database.
# Configure via DATABASE_URL environment variable or modify the connection string below.
DB = Sequel.connect(
  ENV.fetch('DATABASE_URL', 'postgres://synapse:synapse@localhost:5432/synapse'),
  max_connections: 10,
  logger: Logger.new($stdout)
)

# Enable Sequel extensions
DB.extension :pg_array      # PostgreSQL array support (used by cache_invalidation_stream_by_instance)
Sequel.extension :migration  # Migration support

MIGRATIONS_DIR = File.join(__dir__, 'migrations')
MODELS_DIR = File.join(__dir__, 'models')

# Run migrations if needed:
#   Sequel::Migrator.run(DB, MIGRATIONS_DIR)

# Load all models
Dir[File.join(MODELS_DIR, '*.rb')].sort.each { |f| require f }
