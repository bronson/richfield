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
      @options = [':force => true']
      @types = ActiveRecord::Base.connection.native_database_types
    end

    def tables tbls
      tbls.map { |t| table t }.join("\n")
    end

    def table tbl
      options = []
      cols = tbl.columns

      if tbl.primary_key
        if tbl.primary_key == 'id'
          cols = cols.dup.reject { |c| c.name == 'id' }
        else
          options << ":primary_key => #{tbl.primary_key}"
        end
      else
        options << ':id => false'
      end

      options.concat @options
      options_str = options.present? ? options.join(", ")+" " : ""
      "#{indent}create_table :#{tbl.table_name}, #{options_str}do |t|\n#{columns cols}#{indent}end\n"
    end

    # returns the keys in cols in the order that they should be displayed
    def keys_present cols
      [:type, :name].concat(Richfield::ColumnOptions) & cols.map { |k|
        k.members.reject { |v| k[v].nil? }
      }.flatten
    end

    # formats the named value for display
    def format_value col, key
      value = col[key]

      if key == :type
        "t." + value.to_s
      elsif key == :name
        value.inspect + ','
      elsif !value.nil?
        if key == :limit && (value == @types[col.type][:limit] || col.type == :decimal)
          ''
        else
          "#{key.inspect} => #{value.inspect},"
        end
      else
        ''
      end
    end

    def columns cols
      keys = keys_present(cols)
      grid = cols.map { |col| keys.map { |key| format_value col, key } }              # 2D grid of table definition values
      grid.each { |row| row[row.rindex { |f| !f.blank? }].gsub!(/,$/, '') }           # remove trailing commas
      lengths = keys.map { |key| grid.map { |row| row[keys.index(key)].length }.max } # maximum width for each grid column
      grid.map { |row| "#{@indent}  " + row.to_enum.with_index.map { |value,i|
        "%-#{lengths[i]}s " % value }.join.gsub(/\s+$/, '') + "\n"
      }.join
    end
  end
end
