# add logging, default to 1.  0: nothing at all 1: warnings 1: name each table before accessing, 2: show list of models and tables, 3: show columns, 4: show column diffs
# wait, why do I need to specify primary key in the fields block AND on the model?
# also, why do I need id:false on the fields decl if model.primary_key is false or nil?
# add an alias: shortcut to the fields declaration for alias_attribute
# definitely add logging with configurable verbosity
# how does AR ignore tables?  can we do the same thing?
# try to convert to command recorder
# handle down properly (probably means extending commandrecorder)
# any chance of getting rid of richfield_table_options?
# rename_table rename_column
# add_timestamps, remove_timestamps
# add_index, remove_index, rename_index, work with https://github.com/lomba/schema_plus
# change_column_null?

# TO TEST:
# - setup (re-enable test) and schema formatter
# - renames tables if possible
# - renames columns if possible
# - sti
# - counter caches?
# - sti+polymorphic: http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
# - can supply a default name for migration
# - make sure we work with config.active_record.timestamped_migrations = false

# full stack tests:
# - a hideously complex schema with matching tables produces no migration
# - won't run if there are pending migrations
# - prints "models and schema match -- nothing to do"
# - names migration if name isn't supplied.  (probably a bunch of tests: add field, remove field, rename field, rename table, etc)
# - automatically add a fields block when generating models (crib from model_injection.rb and model_generator.rb)
# - prevents model generator from generating a blank migration
# - make sure generator USAGE docs are correct

# thoughts:
# - should probably make fields opt-out instead of opt-in since lots of valid models don't have fields.  fields false?
# - no need to support composed_of relations: https://github.com/rails/rails/pull/6743

require 'rails/generators/active_record/migration/migration_generator'
require 'richfield/migrator'

class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  # this tells where to find this generator's template files
  source_root File.expand_path('../templates', __FILE__)
  class_option :reverse, :type => :boolean, :default => false, :description => "Generate the inverse migration"

  def create_migration_file *args
    # make sure the ActiveRecord migration interface hasn't changed TODO: remove this when we have excellent test coverage
    raise Thor::Error, "API Mismatch?" if ActiveRecord::Generators::MigrationGenerator.all_tasks.except('singular_name').keys != ['create_migration_file']
    return if Richfield.config.check_for_pending_migrations && Richfield::Compatibility.migrations_pending?

    Rails.application.eager_load!
    models = ActiveRecord::Base.descendants.select { |m| m.respond_to? :fields }
    table_names = []
    table_names.concat(ActiveRecord::Base.connection.tables) if Richfield.config.inspect_tables != false
    table_names.concat(ActiveRecord::Base.connection.views) if Richfield.config.inspect_views != false && ActiveRecord::Base.connection.respond_to?(:views)
    table_names -= Richfield.config.ignore_tables
    table_names = table_names.grep(Regexp.new Richfield.config.table_matcher) if Richfield.config.table_matcher
    tables = table_names.map { |table|
      Richfield::TableDefinition.new(table, nil, ActiveRecord::Base.connection.columns(table))
    }

    migrator_args = [models, tables]
    migrator_args.reverse! if options.reverse?
    @migration = Richfield::Migrator.new(*migrator_args).generate
    if file_name == 'show'
      # special case to show the migration instead of saving it
      # TODO 'show' sucks, any way to pass a magic value like '-'?
      source  = File.expand_path(find_in_source_paths('migration.rb'))
      puts ERB.new(File.binread(source), nil, '-', '@output_buffer').result(instance_eval('binding'))
    else
      super(*args)
    end
  end

protected
  attr_reader :migration
end
