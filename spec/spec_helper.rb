require 'active_record'
require 'active_support/core_ext/hash/diff'

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

def model name, &block
  @models ||= []
  @models << Class.new(ActiveRecord::Base) do |m|
    self.table_name = name.to_s
    m.class_eval(&block) if block
  end
end

# TODO: should support migration options: :id => false, :primary_key, etc
def table name, &block
  @tables ||= []
  td = ActiveRecord::ConnectionAdapters::TableDefinition.new(ActiveRecord::Base.connection)
  block.call td if block

  # Convert AR::CA::ColumnDefinition to actual AR::CA::Column objects
  columns = td.columns.map { |column|
    ActiveRecord::ConnectionAdapters::Column.new(column.name, column.default, column.to_sql, column.null)
  }
  @tables << Richfield::TableDefinition.new(name.to_s, 'id', columns)
end

def test_migrator result
  output = Richfield::Migrator.new(@models||[], @tables||[]).generate
  expect(output.to_hash).to eq result
end
