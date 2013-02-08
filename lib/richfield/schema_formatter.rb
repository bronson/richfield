# This is heavily copied from ActiveRecord::SchemaDumper and should produce identical output.
# One day SchemaDumper could be converted to use this to format its output.

# - Get rid of @types and any AR dependency.  We only format, we don't munge.
# to test:
# - can display no columns
# - can display a single column
# - can display a bunch of columns
# - can display a table with no columns
# - can display a table with a bunch of columns
# - display a table with all the :id=>false, :primary_key, :force, etc options
# - output is sorted by input

module Richfield
  class SchemaFormatter
    attr_reader :indent, :options

    def initialize indent
      @indent = indent
      @table_options = [':force => true']
    end

    def tables tbls
      tbls.map { |t| table t }.join("\n")
    end

    def table tbl
      options = tbl.richfield_table_options.merge(@table_options)
      options_str = options.present? ? options.inspect+" " : ""
      "#{indent}create_table :#{tbl.table_name}, #{options_str}do |t|\n#{columns tbl.columns}#{indent}end\n"
    end

    # formats the named value for display
    def format_value column, option
      value = column[option]

      if option == :type
        "t." + value.to_s
      elsif option == :name
        value.inspect + ','
      else
        value = Richfield::Migrator.option_filter(column, option)
        !value.nil? ? "#{option.inspect.gsub(/^{|}$/, '')} => #{value.inspect}," : ''
      end
    end

    def columns cols
      keys = Richfield::ColumnOptions.argument_keys(cols)
      grid = cols.map { |col| keys.map { |key| format_value col, key } }              # 2D grid of table definition values
      grid.each { |row| row[row.rindex { |f| !f.blank? }].gsub!(/,$/, '') }           # remove trailing commas
      lengths = keys.map { |key| grid.map { |row| row[keys.index(key)].length }.max } # maximum width for each grid column
      grid.map { |row| "#{@indent}  " + row.to_enum.with_index.map { |value,i|
        "%-#{lengths[i]}s " % value }.join.gsub(/\s+$/, '') + "\n"
      }.join
    end
  end


  module ColumnOptions
    OptionalKeys = [:limit, :precision, :scale, :default, :null]
    ArgumentKeys = [:name, :type].concat(OptionalKeys)

    # returns options as passed to add_column in the proper order
    def self.argument_keys columns
      all_keys = columns.map { |column|
        column.members.reject { |option| option_filter(column, option).nil? }
      }.flatten
      ArgumentKeys & all_keys # trim to known keys and order for display
    end

    # returns an appropriate display value for this column option or nil if it should be suppressed
    # note: a value of false means the option should still be displayed!
    def self.option_filter column, option
      value = column.send(option)
      return nil if value.nil?

      # don't display limit if it's set to the default
      if option == :limit
        return nil if column.type == :decimal
        types = ActiveRecord::Base.connection.native_database_types
        return nil if value == types[column.type][:limit]
      end

      # only two values for null: empty and false
      if option == :null
        return value == false ? false : nil
      end

      return value
    end

    # converts the column options into a displayable hash
    def self.extract_options column, all_keys
      options = all_keys ? ArgumentKeys : OptionalKeys
      result = {}
      options.each do |option|
        value = option_filter(column, option)
        result[option] = value unless value.nil?
      end
      result
    end
  end
end
