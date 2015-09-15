# gist: https://gist.github.com/catsby/0b676949b6cd414357df
# source https://github.com/gregburek/heroku-buildpack-pgbouncer#disable-prepared-statements

require "active_record/connection_adapters/postgresql_adapter"

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  alias initialize_without_config_boolean_coercion initialize
  def initialize(connection, logger, connection_parameters, config)        
    config = config.merge(prepared_statements: false)        
    initialize_without_config_boolean_coercion(connection, logger, connection_parameters, config)
  end
end