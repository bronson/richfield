require 'richfield/schema_formatter'

module Richfield
  # Just enough model to define a table.  It might be better to modify AR::CA::TableDefinition
  # to keep track of table_name and primary_key?  Or delegate it?
  # TODO: can we replace this with ActiveRecord::ConnectionAdapters::Table?
  TableDefinition = Struct.new(:table_name, :primary_key, :columns)

  # Optional values in a column definition
  ColumnOptions = [:limit, :precision, :scale, :default, :null]

  class Migrator
    def initialize models, tables
      @models = models
      @tables = tables
      @ignore_names = %w[schema_migrations]  # TODO: see hobo_fields always_ignore_tables to ignore CGI sessions table?
    end

    def generate
      desired_tables = {}.merge(model_tables).merge(habtm_tables)
      existing_tables = @tables.index_by(&:table_name)

      create_names = desired_tables.keys - existing_tables.keys - @ignore_names
      drop_names = existing_tables.keys - desired_tables.keys - @ignore_names
      change_names = desired_tables.keys - create_names - drop_names

      create_tables = create_names.sort.map { |name| desired_tables[name] }
      drop_tables = drop_names.sort
      change_commands = change_names.sort.inject([]) { |a,name|
        a.concat detect_changes(desired_tables[name], existing_tables[name])
      }

      Output.new create_tables, drop_tables, change_commands
    end

    def model_tables
      {}.tap do |result|
        @models.each do |model|
          # create an identical table definition where columns contains the desired columns, not the actual ones
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
      [association.foreign_key.to_s, association.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :integer) }
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

    def extract_options column
      result = {}
      ColumnOptions.each do |option|
        val = column.send option
        result[option] = val unless val.nil?
      end
      result.empty? ? nil : result
    end

    def detect_changes model, table
      unless model.table_name == table.table_name
        raise "model name is #{model.table_name} and table name is #{table.table_name}??"
      end

      model_columns = model.columns.index_by { |col| col.name }
      table_columns = table.columns.index_by { |col| col.name }
      to_add = model_columns.keys - table_columns.keys
      to_remove = table_columns.keys - model_columns.keys

      # TODO: can the output be stored in ActiveRecord::Migration::CommandRecorder?
      [].tap do |result|
        to_add.each { |col|
          options = extract_options(model_columns[col])
          change = { call: :add_column, table: model.table_name, name: col, type: model_columns[col].type}
          change.merge!(options: options) if options
          result << change
        }
        to_remove.each { |col| result << { call: :remove_column, table: model.table_name, name: col } }
      end
    end
  end

  class Migrator::Output
    def initialize create_tables, drop_tables, change_tables
      @create_tables = create_tables
      @drop_tables = drop_tables
      @change_tables = change_tables
    end

    def create_tables indent
      Richfield::SchemaFormatter.new(indent).tables(@create_tables)
    end

    def drop_tables indent
      @drop_tables.map { |table|
        "#{indent}drop_table #{table.inspect}\n"
      }.join
    end

    def change_tables indent
      @change_tables.map { |change|
        options = change[:options] ? ", " + change[:options].inspect.gsub(/^{|}$/, '') : ''
        type = change[:type] ? ", " + change[:type].inspect : ''
        "#{indent}#{change[:call]} #{change[:table].inspect}, #{change[:name].inspect}#{type}#{options}\n"
      }.join
    end

    def up_body indent
      [
        create_tables(indent),
        drop_tables(indent),
        change_tables(indent)
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
        result[:change] = @change_tables if @change_tables.present?
      end
    end
  end
end






