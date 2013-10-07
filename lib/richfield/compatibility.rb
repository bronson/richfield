# this module offers helpers to handle the api changes between ActiveRecord 3 and ActiveRecord 4

module Richfield
  module Compatibility
    # AR4 changed TableDefinition's arguments: https://github.com/rails/rails/commit/14d7dc0811fc946ffb63ceed7e0389ed14b50800
    def self.create_table_definition connection, name, options={}
      if ActiveRecord::ConnectionAdapters::TableDefinition.instance_method(:initialize).arity < 4
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection) # AR3
      else
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection.native_database_types, name, false, options) # AR4
      end
    end

    # AR4 changed ColumnDefinition's arguments: https://github.com/rails/rails/commit/cd07f194dc2d8e4278ea9a7d4ccebfe74513b0ac
    def self.create_column_definition connection, name, type
      if ActiveRecord::ConnectionAdapters::ColumnDefinition.members.include?(:base)
        ActiveRecord::ConnectionAdapters::ColumnDefinition.new(connection, name, type) # AR3
      else
        ActiveRecord::ConnectionAdapters::ColumnDefinition.new(name, type) #AR4
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
  end
end