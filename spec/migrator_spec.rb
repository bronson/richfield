require 'spec_helper'

describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    empty = Class.new(ActiveRecord::Base)
    expect(Richfield::Migrator.new([empty],[]).generate.to_hash).to eq({create:[]})
  end

  it "creates an empty table when no fields defined" do
    empty = Class.new(ActiveRecord::Base) {
      self.table_name = :empty
      fields
    }
    expect(Richfield::Migrator.new([empty],[]).generate.to_hash).to eq({
      create: [{table_name: "empty", primary_key: "id", columns: [{:name=>"id", :type=>:primary_key}]}]
      })
  end

  it "creates a simple table"

  it "handles a polymorphic association"
  it "creates a habtm table"

  it "adds a simple column"
  it "removes a simple column"

  it "removes a simple association"
  it "removes a polymorphic association"
  it "removes a habtm table"

  it "renames columns where possible"
  it "renames tables where possible"

  it "automatically adds an index for references"
  it "automatically adds an index for foreign key"
  it "doesn't add an index if told not to"

  it "automatically names the migration if possible"
end

# these require testing with the full rails stack:
# it "won't run if there are pending migrations"
# it "works with config.active_record.timestamped_migrations = false"
