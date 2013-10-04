module Richfield
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :richfield_table_options

      def richfield_definition vivify=true
        # todo: gotta be a better API than this vivify stuff
        @richfield_definiton ||= (vivify ? Richfield::Compatibility.create_table_definition(connection, table_name, {}) : nil)
      end

      def fields options={}
        cols = richfield_definition
        @richfield_table_options = options
        yield cols if block_given?
      end
    end
  end

  module Compatibility
    # papers over api changes between AR3 and AR4
    def self.create_table_definition connection, name, options
      if ActiveRecord::ConnectionAdapters::TableDefinition.instance_method(:initialize).arity == 4
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection.native_database_types, name, false, options) # AR4
      else
        ActiveRecord::ConnectionAdapters::TableDefinition.new(connection) # AR3
      end
    end

    def self.column_to_sql connection, column
      if column.respond_to? :to_sql
        column.to_sql    # AR3
      else
        ActiveRecord::Base.connection.schema_creation.accept(column)   # AR4
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
