require 'active_record'

$:.unshift File.expand_path("../../lib", __FILE__)
require 'richfield/migrator'
require 'richfield/active_record_base'

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end


# because we're using real models, AR complains if there's no open db connection
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

# delete any model classes when we're done
RSpec.configure do |config|
  config.after(:each) do
    @models and @models.each { |model| Object.send :remove_const, model.name.to_sym }
  end
  Richfield.reset_config
end


# creates a fake model
def model name, parent=ActiveRecord::Base, &block
  @models ||= []
  raise 'Duplicate #{name} definition' if Object.const_defined? name

  model = Class.new(parent)
  @models << model
  Object.const_set(name, model)
  model.class_eval(&block) if block
  model
end


# creates a fake table
def table name, options={}
  @tables ||= []
  tabledef = Richfield::Compatibility.create_table_definition(ActiveRecord::Base.connection, name, options)
  yield(tabledef) if block_given?

  # Convert the AR::CA::ColumnDefinitions to actual AR::CA::Column objects to match real life
  columns = tabledef.columns.map do |column|
    sql = Richfield::Compatibility.column_to_sql(ActiveRecord::Base.connection, column)
    ActiveRecord::ConnectionAdapters::Column.new(column.name, column.default, sql, column.null)
  end

  result = Richfield::TableDefinition.new(name.to_s, options, columns)
  @tables << result
  result
end


def test_migrator result
  output = Richfield::Migrator.new(@models||[], @tables||[]).generate
  expect(output.to_hash).to eq result
end
