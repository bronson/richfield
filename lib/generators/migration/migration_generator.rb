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
    model_tables = models.map(&:table_name)
    db_tables = tables

    create_tables = model_tables - db_tables
    drop_tables = db_tables - model_tables
    Results.new create_tables, drop_tables
  end

  def models
    Rails.application.eager_load!
    ActiveRecord::Base.descendants # .select { |m| m.respond_to? :fields }
  end

  def tables
    ActiveRecord::Base.connection.tables
  end
end


class Migrator::Formatter
  def initialize create_tables, drop_tables
    @create_tables = create_tables
    @drop_tables = drop_tables
  end

  def create_tables indent
    @create_tables.map { |t| "#{indent}create_table :#{t}\n" }.join
  end

  def drop_tables
  end

  def up_body indent
    create_tables indent
  end

  def down_body indent
  end
end

