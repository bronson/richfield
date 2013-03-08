require 'active_support/configurable'

module Richfield
  include ActiveSupport::Configurable

  def self.reset_config
    Richfield.config.keys.each { |k| Richfield.config.delete k }

    Richfield.config.ignore_tables = %w[schema_migrations]
    Richfield.config.check_for_pending_migrations = true
  end
end

Richfield.reset_config
