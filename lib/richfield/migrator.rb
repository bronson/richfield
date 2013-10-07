require 'richfield/configuration'
require 'richfield/schema_formatter'

module Richfield
  # Just enough model to keep track of a table definiton.  It's probably
  # time to turn this into a full blown class.  (TODO: so why can't we use AR:CA::TableDefinition?)
  TableDefinition = Struct.new(:table_name, :richfield_table_options, :columns) do
    def primary_key
      return nil if richfield_table_options[:id] == false
      richfield_table_options[:primary_key] || 'id'
    end

    def connection
      nil
    end
  end

  class Migrator
    def initialize models, tables
      @models = models
      @tables = tables
    end

    def generate
      desired_tables = {}.merge(model_tables).merge(habtm_tables)
      existing_tables = @tables.index_by(&:table_name)

      create_names = desired_tables.keys - existing_tables.keys
      drop_names = existing_tables.keys - desired_tables.keys
      change_names = desired_tables.keys - create_names - drop_names

      create_tables = create_names.sort.map { |name| desired_tables[name] }
      drop_tables = drop_names.sort
      change_commands = change_names.sort.inject([]) { |a,name|
        a.concat detect_changes(desired_tables[name], existing_tables[name])
      }

      Output.new create_tables, drop_tables, change_commands
    end

    def model_tables
      result = {}
      @models.each do |model|
        # create an identical table definition where columns contains the desired columns, not the actual ones
        raise "richfield's ActiveRecord extension wasn't loaded" unless model.respond_to? :richfield_fields
        next if model.richfield_is_sti_child?   # we only need to process the base STI class

        if model.richfield_fields
          columns = model.richfield_fields_create.columns.dup
          add_belongs_to_columns(model, columns)
          add_sti_columns(model, columns)
          # puts "Guessed fields for #{model.name}: #{columns.map(&:name) - model.richfield_fields_create.columns.map(&:name)}"
          table_definition = TableDefinition.new(model.table_name, model.richfield_fields.options, columns)
          result.merge! model.table_name => table_definition
        end
      end
      result
    end

    def define_join_table association
      table_name = association.options[:join_table]
      table = Richfield::Compatibility.create_table_definition(association.active_record.connection, table_name)
      [association.foreign_key.to_s, association.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :integer) }
      { table_name => TableDefinition.new(table_name, { id: false }, table.columns) }
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

    def hash_of_names objects
      # returns a hash of the names with a value of true to check presence.
      # why can't I make this simple concept readable???
      # objects.inject({}) { |h,col| h.merge! col.name => true }
      Hash[*objects.map { |col| [col.name.to_s, true] }.flatten]
    end

    def add_belongs_to_columns model, columns
      # merges any columns that we need to guess in with existing columns
      # don't let our guesses override the declarations in the fields block
      names = hash_of_names(columns)
      model.reflect_on_all_associations(:belongs_to).each do |association|
        if names[association.foreign_key.to_s].nil?
          columns << Richfield::Compatibility.create_column_definition(model.connection, association.foreign_key, :integer)
        end
        if association.options[:polymorphic] && names[association.foreign_type].nil?
          columns << Richfield::Compatibility.create_column_definition(model.connection, association.foreign_type, :string)
        end
      end
      columns
    end

    def add_sti_columns model, columns
      if model.richfield_fields.using_sti? && model.superclass == ActiveRecord::Base
        names = hash_of_names(columns)
        if names[model.inheritance_column.to_s].nil?
          column = Richfield::Compatibility.create_column_definition(model.connection, model.inheritance_column, :string)
          column.null = false
          columns << column
        end
      end
      columns
    end

    def create_change call, model, column
      options = Richfield::ColumnOptions.extract_options(column, false)
      change = { call: call, table: model.table_name, name: column.name, type: column.type }
      change.merge!(options: options) unless options.empty?
      change
    end

    # used to be in activesupport, now deprecated
    def hash_diff me, other
      me.dup.
        delete_if { |k, v| other[k] == v }.
        merge!(other.dup.delete_if { |k, v| me.has_key?(k) })
    end

    def detect_changes model, table
      unless model.table_name == table.table_name
        raise "model name is #{model.table_name} and table name is #{table.table_name}??"
      end

      model_columns = model.columns.index_by { |col| col.name }
      table_columns = table.columns.index_by { |col| col.name }

      to_add = model_columns.keys - table_columns.keys
      to_remove = table_columns.keys - model_columns.keys
      to_change = model_columns.keys - to_add - to_remove

      # TODO: can the output be stored in ActiveRecord::Migration::CommandRecorder?
      [].tap do |result|
        if model.primary_key
          to_remove -= [model.primary_key.to_s]  # if the table has a pk, don't remove it just b/c the fieldspec doesn't
          if !model_columns[model.primary_key.to_s] && !table_columns[model.primary_key.to_s]
            # model specifies a primary key that isn't the table and not defined in the fields.  Add it.
            column = Richfield::Compatibility.create_column_definition(model.connection, model.primary_key, :primary_key)
            result << create_change(:add_column, model, column)
          end
        end

        to_add.each do |column|
          result << create_change(:add_column, model, model_columns[column])
        end

        to_change.each do |column|
          model_args = Richfield::ColumnOptions.extract_options(model_columns[column], true)
          table_args = Richfield::ColumnOptions.extract_options(table_columns[column], true)
          if !hash_diff(model_args, table_args).empty?
            result << create_change(:change_column, model, model_columns[column])
          end
        end

        to_remove.each { |col| result << { call: :remove_column, table: model.table_name, name: col } }
      end
    end
  end

  class Migrator::Output
    # TODO: make indent be attr_accessor so we can change it w/o creating whole new class?
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

    def to_hash
      {}.tap do |result|
        result[:create] = [] if @create_tables.present?
        @create_tables.each do |table|
          columns = table.columns.map { |column|
            Richfield::ColumnOptions.extract_options(column, true)
          }
          result[:create] << { table_name: table.table_name, options: table.richfield_table_options, columns: columns }.delete_if { |k,v| k == :options && v.empty? }
        end
        result[:drop] = @drop_tables if @drop_tables.present?
        result[:change] = @change_tables if @change_tables.present?
      end
    end
  end
end






