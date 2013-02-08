require 'active_support/configurable'

module Richfield
  include ActiveSupport::Configurable

  def self.reset_config
    Richfield.config.keys.each { |k| Richfield.config.delete k }
    Richfield.config.ignore_tables = %w[schema_migrations]  # TODO: see hobo_fields always_ignore_tables to ignore CGI sessions table?
  end
end

Richfield.reset_config
