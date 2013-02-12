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


def model name, &block
  @models ||= []
  raise 'Duplicate #{name} definition' if Object.const_defined? name

  model = Class.new(ActiveRecord::Base) do |m|
    m.class_eval(&block) if block
  end

  result = Object.const_set(name, model)
  @models << result
  result
end


def table name, options={}, &block
  @tables ||= []
  td = ActiveRecord::ConnectionAdapters::TableDefinition.new(ActiveRecord::Base.connection)
  block.call td if block

  # Convert the AR::CA::ColumnDefinitions to actual AR::CA::Column objects
  columns = td.columns.map { |column|
    ActiveRecord::ConnectionAdapters::Column.new(column.name, column.default, column.to_sql, column.null)
  }

  result = Richfield::TableDefinition.new(name.to_s, options, columns)
  @tables << result
  result
end


def test_migrator result
  output = Richfield::Migrator.new(@models||[], @tables||[]).generate
  expect(output.to_hash).to eq result
end
