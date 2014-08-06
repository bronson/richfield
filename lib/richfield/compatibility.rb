# this module offers helpers to handle the api changes between ActiveRecord 3 and ActiveRecord 4

module Richfield
  module Compatibility
    # AR4 changed TableDefinition's arguments: https://github.com/rails/rails/commit/14d7dc0811fc946ffb63ceed7e0389ed14b50800
    def self.create_table_definition connection, name, options={}
      # Is there a good way of testing how many arguments to pass?  This is too brittle:
      #    ActiveRecord::ConnectionAdapters::TableDefinition.instance_method(:initialize).arity < 4
      if ActiveRecord.respond_to?(:version) && ActiveRecord.version.to_s.to_f >= 4.0
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection.native_database_types, name, false, options) # AR4
      else
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection) # AR3
      end
    end

    # AR4 changed ColumnDefinition's arguments: https://github.com/rails/rails/commit/cd07f194dc2d8e4278ea9a7d4ccebfe74513b0ac
    def self.create_column_definition connection, name, type
      unless ActiveRecord::ConnectionAdapters::ColumnDefinition.members.include?(:base)
        ActiveRecord::ConnectionAdapters::ColumnDefinition.new(name, type) #AR4
      else
        ActiveRecord::ConnectionAdapters::ColumnDefinition.new(connection, name, type) # AR3
      end
    end

    # AR4 removed TableDefinition.to_sql: https://github.com/rails/rails/commit/1c9f7fa6e17d3b026ad6e0bc1f07a9dd47d8a360
    def self.column_to_sql connection, column
      if column.respond_to?(:to_sql)
        column.to_sql    # AR3
      else
        connection.schema_creation.accept(column)   # AR4
      end
    end

    def self.join_table association
      if association.respond_to? :join_table
        association.join_table
      else
        association.options[:join_table]
      end
    end

    # AR4 changed the Migrator but added a call to check migration
    def self.migrations_pending?
      if ActiveRecord::Migration.respond_to? :check_pending!
        # Rails 4+
        ActiveRecord::Migration.check_pending!
      else
        # Rails 3
        pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
        if pending_migrations.any?
          say "You have #{pending_migrations.size} pending migration#{'s' if pending_migrations.size > 1}:"
          pending_migrations.each do |pending_migration|
            say '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          return true
        end
      end
      false
    end
  end
end
