module Richfield
  module ActiveRecord
    module Base
      extend ActiveSupport::Concern

      module ClassMethods
        def richfield_definition
          # this comes from AR::CA::SchemaStatements#create_table.  Refactor to remove duplication?
          @richfield_definiton ||= ::ActiveRecord::ConnectionAdapters::TableDefinition.new(connection)
        end

        def fields options={}
          cols = richfield_definition
          cols.primary_key(options[:primary_key] || ::ActiveRecord::Base.get_primary_key(table_name.to_s.singularize)) unless options[:id] == false
          yield cols if block_given?
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecord::Base
