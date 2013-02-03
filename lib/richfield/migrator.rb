class Migrator
  def generate
    desired_tables = {}.merge(model_tables).merge(habtm_tables)
    create_names = desired_tables.keys - existing_tables
    drop_names = existing_tables - desired_tables.keys

    create_tables = create_names.map { |name| desired_tables[name] }
    Formatter.new create_tables, drop_names
  end

  def models
    @models ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.select { |m| m.respond_to? :fields }
    end
  end

  def model_tables
    models.inject({}) do |result,model|
      # create an identical table definition except columns reflects the desired columns, not the actual ones
      table_definition = Migrator::TableDefinition.new(model.table_name, model.primary_key, model.richfield_definition.columns)
      result.merge! model.table_name => table_definition
    end
  end

  def define_join_table association, connection
    table_name = association.options[:join_table]
    table = ActiveRecord::ConnectionAdapters::TableDefinition.new(connection)
    [association.foreign_key.to_s, association.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :references) }
    { table_name => Migrator::TableDefinition.new(table_name, false, table.columns) }
  end

  def habtm_tables
    # this creates the habtm table when one model is loaded, then again when the other is.
    # since they're supposed to be identical this should be no big deal...?
    models.inject({}) do |mh,model|
      mh.merge! model.reflect_on_all_associations(:has_and_belongs_to_many).inject({}) { |ah,association|
        ah.merge! define_join_table(association, model.connection)
      }
    end
  end

  def existing_tables
    ActiveRecord::Base.connection.tables
  end
end


# Behaves like a fake model, for instance for habtm tables.  Might be better to just
# modify AR::CA::TableDefinition to keep track of table_name and primary_key?  Or delegate it.
Migrator::TableDefinition = Struct.new(:table_name, :primary_key, :columns)


class Migrator::Formatter
  def initialize create_tables, drop_tables
    @create_tables = create_tables
    @drop_tables = drop_tables
  end

  def create_tables indent
    ActiveRecord::Dumper.new(indent).tables(@create_tables)
  end

  def drop_tables
  end

  def up_body indent
    create_tables indent
  end

  def down_body indent
  end
end


# This is heavily copied from ActiveRecord::SchemaDumper and should produce identical output.
# Hope one day SchemaDumper can be converted to use this dumper.
class ActiveRecord::Dumper
  attr_reader :indent, :options

  def initialize indent
    @indent = indent
    @options = [':force => true']
    @types = ActiveRecord::Base.connection.native_database_types
  end

  def tables tbls
    tbls.sort_by(&:table_name).map { |t| table t }.join("\n")
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
    [:type, :name, :limit, :precision, :scale, :default, :null] & cols.map { |k|
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
