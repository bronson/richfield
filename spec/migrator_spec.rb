require 'spec_helper'

describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    test_migrator(
      model(:ignored),
      { create: [] }
    )
  end

  it "creates an primary key when no fields defined" do
    test_migrator(
      model(:empty) { fields },
      { create: [
        {table_name: "empty", primary_key: "id", columns: [
          {:name=>"id", :type=>:primary_key}    # still has primary key column
        ]}
      ]} )
  end

  it "creates a table with no columns when no fields and no primary key" do
    test_migrator(
      model(:truly_empty) { fields :id => false },
      {create: [{table_name: "truly_empty", primary_key: "id", columns: []} ]}
    )
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
