# Testing column-oriented commands: add_column, remove_column, change_column, etc

require File.expand_path("../../spec_helper", __FILE__)


# TODO: get rid of limit:255 nonsense

describe Richfield::Migrator do
  it "adds a type column when sti is used"   # when subclasses exist but they don't declare any fields
  it "handles fields declarations in sti subclasses"   # when subclasses declare fields

  it "adds a column to a truly empty table" do
    test_migrator(
      model(:truly_empty) {
        fields :id => false do |t|
          t.string :name, :default => "nope"
        end
      },
      table(:truly_empty) {
      },
      { change: [
        { call: :add_column, table: 'truly_empty', name: 'name', type: :string, options: { limit: 255, default: "nope" } }
      ]}
    )
  end

  it "update simple relations" do
    test_migrator(
      model(:handlers) {
        fields
        belongs_to :dog
      },
      model(:dogs) {
        fields
        has_many :handlers
      },

      table(:handlers) { |t|
        t.integer :id
      },
      table(:dogs) { |t|
        t.integer :id
        t.integer :handler_id
      },

      { change: [
        { call: :remove_column, table: "dogs",     name: "handler_id" },
        { call: :add_column,    table: "handlers", name: "dog_id", type: :integer }
      ]}
    )
  end

  it "changes a column that's now :null => false"
  it "changes a column that's now :null => nil or :null => true"

  it "adds a table's primary key"
  it "removes a table's primary key"
  it "changes a table's primary key"

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
