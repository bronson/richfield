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


# TODO: factor activerecord out of the migrator, use shims to allow any ORM
class Migrator
  def generate
    create_table_names = models.keys - db_table_names
    drop_tables = db_table_names - models.keys

    creates = create_table_names.map { |name| models[name] }
    Formatter.new creates, drop_tables
  end

  # returns a hash of all tracked models indexed by table_name
  def models
    Rails.application.eager_load!
    @models ||= ActiveRecord::Base.descendants.select { |m| m.respond_to? :fields }.inject({}) { |h,m| h.merge! m.table_name => m }
  end

  def db_table_names
    ActiveRecord::Base.connection.tables
  end
end


class Migrator::Formatter
  def initialize create_tables, drop_tables
    @create_tables = create_tables
    @drop_tables = drop_tables
  end

  # creates a TableDefinition lookalike for the model's fields
  def table_fields_definition model
    columns = model.instance_variable_get('@fields_definition').columns
    Struct.new(:table_name, :primary_key, :columns).new(model.table_name, model.primary_key, columns)
  end

  def create_tables indent
    dumper = ActiveRecord::Dumper.new indent
    tables = @create_tables.map { |tbl| table_fields_definition tbl }
    dumper.tables tables
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
  # BUG? deleting the , at the end of a short line leaves longer lines indented 1 character too far
  attr_reader :indent, :options

  def initialize indent
    @indent = indent
    @options = [':force => true']
    @types = ActiveRecord::Base.connection.native_database_types
  end

  def tables tbls
    tbls.sort_by(&:table_name).map { |t| table t }.join
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

  def keys_present cols
    [:type, :name, :limit, :precision, :scale, :default, :null] & cols.map { |k|
      k.members.reject { |v| k[v].nil? }
    }.flatten
  end

  def spec col, k
    v = col[k]

    if k == :type
      v.to_s
    elsif k == :name
      v.inspect + ','
    elsif !v.nil?
      if k == :limit && (v == @types[col.type][:limit] || col.type == :decimal)
        ''
      else
        "#{k.inspect} => #{v.inspect},"
      end
    else
      ''
    end
  end

  def columns cols
    keys = keys_present(cols)
    lengths = keys.inject({}) { |a,k|
      a.merge! k => cols.map { |c| !c[k].nil? ? spec(c,k).length : 0 }.max
    }
    cols.map { |c| column c, keys, lengths }.join
  end

  def column col, keys, lengths
    "#{indent}  t." + keys.map { |k| "%-#{lengths[k]}s" % spec(col,k) }.join(" ").sub(/,\s*$/, '') + "\n"
  end
end
