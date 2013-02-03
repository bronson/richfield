require 'richfield/schema_formatter'

module Richfield
  # Just enough model to define a table.  It might be better to modify AR::CA::TableDefinition
  # to keep track of table_name and primary_key?  Or delegate it?
  TableDefinition = Struct.new(:table_name, :primary_key, :columns)

  class Migrator
    def initialize models, tables
      @models = models
      @tables = tables
    end

    def generate
      desired_tables = {}.merge(model_tables).merge(habtm_tables)
      create_names = desired_tables.keys - @tables
      drop_names = @tables - desired_tables.keys

      create_tables = create_names.map { |name| desired_tables[name] }
      Output.new create_tables, drop_names
    end

    def model_tables
      @models.inject({}) do |result,model|
        # create an identical table definition except columns reflects the desired columns, not the actual ones
        table_definition = TableDefinition.new(model.table_name, model.primary_key, model.richfield_definition.columns)
        result.merge! model.table_name => table_definition
      end
    end

    def define_join_table association, connection
      table_name = association.options[:join_table]
      table = ActiveRecord::ConnectionAdapters::TableDefinition.new(connection)
      [association.foreign_key.to_s, association.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :references) }
      { table_name => TableDefinition.new(table_name, false, table.columns) }
    end

    def habtm_tables
      # this creates the habtm table when one model is loaded, then again when the other is.
      # since they're supposed to be identical this should be no big deal...?
      @models.inject({}) do |mh,model|
        mh.merge! model.reflect_on_all_associations(:has_and_belongs_to_many).inject({}) { |ah,association|
          ah.merge! define_join_table(association, model.connection)
        }
      end
    end
  end

  class Migrator::Output
    def initialize create_tables, drop_tables
      @create_tables = create_tables
      @drop_tables = drop_tables
    end

    def create_tables indent
      Richfield::SchemaFormatter.new(indent).tables(@create_tables)
    end

    def drop_tables
    end

    def up_body indent
      create_tables indent
    end

    def down_body indent
    end
  end
end






