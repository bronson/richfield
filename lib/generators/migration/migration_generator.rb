# create_table, drop_table, rename_table, add_column, remove_column, rename_column, change_column, change_column_null?, add_index, remove_index, rename_index, add_timestamps, remove_timestamps

# TO TEST:
# - drops tables
# - removes columns and references
# - renames columns if possible
# - renames table if possible
# - sti
# - won't run if there are pending migrations
# - prints "models and schema match -- nothing to do"
# - names migration if name isn't supplied.  (probably a bunch of tests: add field, remove field, rename field, rename table, etc)
# - automatically add a fields block when generating models (crib from model_injection.rb and model_generator.rb)
# - make sure we work with config.active_record.timestamped_migrations = false
# - should probably make fields opt-out instead of opt-in since lots of valid models don't have fields.  fields false?


require 'rails/generators/active_record/migration/migration_generator'
require 'richfield/migrator'

class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  # this tells where to find this generator's template files
  source_root File.expand_path('../templates', __FILE__)

  def create_migration_file *args
    # make sure the ActiveRecord migration interface hasn't changed TODO: remove this when we have excellent test coverage
    raise Thor::Error, "API Mismatch?" if ActiveRecord::Generators::MigrationGenerator.all_tasks.except('singular_name').keys != ['create_migration_file']
    return if migrations_pending?

    Rails.application.eager_load!
    models = ActiveRecord::Base.descendants.select { |m| m.respond_to? :fields }
    tables = ActiveRecord::Base.connection.tables
    @migration = Richfield::Migrator.new(models,tables).generate
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
