# create_table, drop_table, rename_table, add_column, remove_column, rename_column, change_column, add_index, remove_index, rename_index, add_timestamps, remove_timestamps

# TO TEST:
# - won't run if there are pending migrations
# - prints "models and schema match -- nothing to do"
# - names migration if name isn't supplied.  (probably a bunch of tests: add field, remove field, rename field, rename table, etc)
# - renames columns if possible
# - renames table if possible
# - sti
# - polymorphic
# - habtm
# - make sure we work with config.active_record.timestamped_migrations = false

# make sure fields do { } and fields; add_column work?  Do we really need the second syntax?


# up,down = Generators::Hobo::Migration::Migrator.new(lambda{|c,d,k,p| extract_renames!(c,d,k,p)}).generate

require 'rails/generators/active_record/migration/migration_generator'

class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  # this tells where to find this generator's template files
  source_root File.expand_path('../templates', __FILE__)

  def create_migration_file *args
    # make sure the ActiveRecord migration interface hasn't changed TODO: remove this when we have excellent test coverage
    raise Thor::Error, "API Mismatch?" if ActiveRecord::Generators::MigrationGenerator.all_tasks.except('singular_name').keys != ['create_migration_file']
    return if migrations_pending?

    @migration = Migrator.new.generate
    super(*args)
  end

  protected
  attr_reader :migration

  def migrations_pending?
    pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations

    if pending_migrations.any?
      say "You have #{pending_migrations.size} pending migration#{'s' if pending_migrations.size > 1}:"
      pending_migrations.each do |pending_migration|
        say '  %4d %s' % [pending_migration.version, pending_migration.name]
      end
      true
    else
      false
    end
  end
end


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
    models.inject({}) do |h,m|
      # create an identical table definition except columns reflects the desired columns, not the actual ones
      table_definition = Migrator::TableDefinition.new(m.table_name, m.primary_key, m.richfield_definition.columns)
      h.merge! m.table_name => table_definition
    end
  end

  def join_table assoc, connection
    table_name = assoc.options[:join_table]
    table = ActiveRecord::ConnectionAdapters::TableDefinition.new(connection)
    [assoc.foreign_key.to_s, assoc.association_foreign_key.to_s].sort.each { |aname| table.column(aname, :references) }
    { table_name => Migrator::TableDefinition.new(table_name, false, table.columns) }
  end

  def habtm_tables
    models.inject({}) do |mh,m|
      mh.merge! m.reflect_on_all_associations(:has_and_belongs_to_many).inject({}) { |ah,a| ah.merge! join_table(a, m.connection) }
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
