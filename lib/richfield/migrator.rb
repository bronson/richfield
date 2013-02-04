require 'richfield/schema_formatter'

module Richfield
  # Just enough model to define a table.  It might be better to modify AR::CA::TableDefinition
  # to keep track of table_name and primary_key?  Or delegate it?
  TableDefinition = Struct.new(:table_name, :primary_key, :columns)

  class Migrator
    def initialize models, tables
      @models = models
      @tables = tables
      @ignore_names = %w[schema_migrations]
    end

    def generate
      desired_tables = {}.merge(model_tables).merge(habtm_tables)
      create_names = desired_tables.keys - @tables - @ignore_names
      drop_names = @tables - desired_tables.keys - @ignore_names

      create_tables = create_names.sort.map { |name| desired_tables[name] }
      drop_tables = drop_names.sort
      Output.new create_tables, drop_tables
    end

    def model_tables
      {}.tap do |result|
        @models.each do |model|
          # create an identical table definition except columns reflects the desired columns, not the actual ones
          raise "richfield's ar extension wasn't loaded" unless model.respond_to? :richfield_definition
          unless model.richfield_definition(false).nil?
            table_definition = TableDefinition.new(model.table_name, model.primary_key, model.richfield_definition.columns)
            result.merge! model.table_name => table_definition
          end
        end
      end
    end

    def define_join_table association
      table_name = association.options[:join_table]
      table = ActiveRecord::ConnectionAdapters::TableDefinition.new(association.active_record.connection)
      [association.foreign_key.to_s, association.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :references) }
      { table_name => TableDefinition.new(table_name, false, table.columns) }
    end

    def habtm_tables
      # this creates the habtm table when one model is loaded, then again when the other is.
      # since they're supposed to be identical this should be no big deal...?
      @models.inject({}) do |mh,model|
        mh.merge! model.reflect_on_all_associations(:has_and_belongs_to_many).inject({}) { |ah,association|
          ah.merge! define_join_table(association)
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

    def drop_tables indent
      @drop_tables.map { |table|
        "#{indent}drop_table #{table.inspect}\n"
      }.join
    end

    def up_body indent
      [
        create_tables(indent),
        drop_tables(indent)
      ].reject(&:blank?).join("\n")
    end

    def down_body indent
    end


    # everything below here is just for testability

    def struct_to_hash s
      Hash[s.each_pair.to_a]
    end

    def to_hash
      {}.tap do |result|
        result[:create] = [] if @create_tables.present?
        @create_tables.each do |table|
          columns = table.columns.map { |col| struct_to_hash(col).reject { |k,v| k == :base || v.nil? } }
          result[:create] << struct_to_hash(table).merge(columns: columns)
        end
        result[:drop] = @drop_tables if @drop_tables.present?
      end
    end
  end
end






