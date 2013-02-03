#ENV["RAILS_ENV"] ||= 'test'
#require File.expand_path("../../config/environment", __FILE__)
#Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

require 'active_record'
require File.expand_path("../../lib/richfield/migrator", __FILE__)
require File.expand_path("../../lib/richfield/active_record_base", __FILE__)

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
  Class.new(ActiveRecord::Base) do |m|
    self.table_name = name
    m.class_eval(&block) if block
  end
end
