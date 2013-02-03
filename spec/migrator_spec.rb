require 'spec_helper'

describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    expect(Richfield::Migrator.new([model('ignored')],[]).generate.to_hash).to eq({create:[]})
  end

  it "creates an empty table when no fields defined" do
    empty = model(:empty) { fields }
    expect(Richfield::Migrator.new([empty],[]).generate.to_hash).to eq({
      create: [
        {table_name: "empty", primary_key: "id", columns: [
          {:name=>"id", :type=>:primary_key}    # even empty tables have an id column
        ]} ]
    })
  end

  it "creates a truly empty table when no fields and no primary key" do
    empty = model(:truly_empty) { fields :id => false }
    expect(Richfield::Migrator.new([empty],[]).generate.to_hash).to eq({
      create: [ {table_name: "truly_empty", primary_key: "id", columns: []} ]
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
