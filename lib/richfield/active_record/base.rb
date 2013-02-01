module Richfield
  module ActiveRecord
    module Base
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :model_fields

        def fields options={}
          # this nontrivial code comes from AR::CA::SchemaStatements#create_table.  Refactor?
          td = ::ActiveRecord::ConnectionAdapters::TableDefinition.new(connection)
          td.primary_key(options[:primary_key] || ::ActiveRecord::Base.get_primary_key(table_name.to_s.singularize)) unless options[:id] == false

          yield td if block_given?
          @fields_definition = td
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecord::Base
