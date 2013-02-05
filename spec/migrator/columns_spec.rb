# Testing column-oriented commands: add_column, remove_column, change_column, etc

require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  it "adds a type column when sti is used"   # when subclasses exist but they don't declare any fields
  it "handles fields declarations in sti subclasses"   # when subclasses declare fields

  it "adds a column to a truly empty table" do
    model :truly_empty do
      fields :id => false do |t|
        t.string :name, :default => "nope"
      end
    end

    table :truly_empty do
    end

    test_migrator(
      { change: [
        { call: :add_column, table: 'truly_empty', name: 'name', type: :string, options: { default: "nope" } }
      ]}
    )
  end

  it "handles switching belongs_to ownership" do
    model(:handlers) {
      fields
      belongs_to :dog
    }
    model(:dogs) {
      fields
      has_many :handlers
    }

    table(:handlers) { |t|
      t.primary_key :id
    }
    table(:dogs) { |t|
      t.primary_key :id
      t.integer :handler_id
    }

    test_migrator(
      { change: [
        { call: :remove_column, table: "dogs",     name: "handler_id" },
        { call: :add_column,    table: "handlers", name: "dog_id", type: :integer }
      ]}
    )
  end

  it "adds a polymorphic association" do
    model(:comments) {
      fields do |t|
        t.text :content
      end
      belongs_to :commentable, polymorphic: true
    }

    table(:comments) { |t|
      t.primary_key :id
      t.text :content
    }

    test_migrator(
      { change: [
        { call: :add_column, table: "comments", name: "commentable_id", type: :integer},
        { call: :add_column, table: "comments", name: "commentable_type", type: :string }
      ]}
    )
  end

  it "removes a polymorphic association" do
    model(:comments) {
      fields do |t|
        t.text :content
      end
    }

    table(:comments) { |t|
      t.primary_key :id
      t.text :content
      t.integer :commentable_id
      t.string :commentable_type
    }

    test_migrator(
      { change: [
        { call: :remove_column, table: "comments", name: "commentable_id" },
        { call: :remove_column, table: "comments", name: "commentable_type" }
      ]}
    )
  end

  it "adds a habtm table" do
    model(:users) {
      fields do |t|
        t.string :name
      end
      has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
    }

    model(:roles) {
      fields
      has_and_belongs_to_many :users, foreign_key: 'role_id', association_foreign_key: 'user_id', join_table: 'roles_users'
    }

    table(:users) { |t|
      t.primary_key :id
      t.string :name
    }

    table(:roles) { |t|
      t.primary_key :id
    }

    test_migrator(
      { create: [
        { table_name: "roles_users", primary_key: false, columns: [
          { name: "role_id", type: :integer },
          { name: "user_id", type: :integer }
        ]}
      ]}
    )
  end

  it "removes a habtm table" do
    model(:users) {
      fields do |t|
        t.string :name
      end
    }

    model(:roles) {
      fields
    }

    table(:users) { |t|
      t.primary_key :id
      t.string :name
    }

    table(:roles) { |t|
      t.primary_key :id
    }

    table(:roles_users) { |t|
      t.integer :role_id
      t.integer :user_id
    }

    test_migrator(
      { drop: [ "roles_users" ]}
    )
  end

  it "changes a column from an integer to a string" do
    model(:changing_table) {
      fields :id => false do |t|
        t.string :year
      end
    }

    table(:changing_table) { |t|
      t.integer :year
    }

    test_migrator(
      { change: [
        { call: :change_column, table: "changing_table", name: "year", type: :string }
      ]}
    )
  end

  it "changes a column that's now :null => false" do
    model(:non_null) {
      fields :id => false do |t|
        t.string :name, :null => false
      end
    }

    table(:non_null) { |t|
      t.string :name
    }

    test_migrator(
      { change: [
        { call: :change_column, table: "non_null", name: "name", type: :string, options: { null: false }}
      ]}
    )
  end

  it "changes a column that's no longer :null => false" do
    model(:nullable) {
      fields :id => false do |t|
        t.string :name  # null is default
      end
    }

    table(:nullable) { |t|
      t.string :name, :null => false
    }

    test_migrator(
      { change: [
        { call: :change_column, table: "nullable", name: "name", type: :string }
      ]}
    )
  end

  it "ignores a model column that's :null => true" do
    model(:nullable) {
      fields :id => false do |t|
        t.string :name, null: true
      end
    }

    table(:nullable) { |t|
      t.string :name
    }

    test_migrator({})
  end

  it "ignores a table column that's :null => true" do
    model(:nullable) {
      fields :id => false do |t|
        t.string :name
      end
    }

    table(:nullable) { |t|
      t.string :name, null: true
    }

    test_migrator({})
  end

  it "adds a table's primary key" do
    model(:now_with_key) {
      fields do |t|
        t.string :name
      end
    }

    table(:now_with_key) { |t|
      t.string :name
    }

    test_migrator(
      { change: [
        { call: :add_column, table: "now_with_key", name: "id", type: :primary_key }
      ]}
    )
  end

  it "removes a table's primary key" do
    model(:now_no_key) {
      fields id: false do |t|
        t.string :name
      end
    }

    table(:now_no_key) { |t|
      t.primary_key :id
      t.string :name
    }

    test_migrator(
      { change: [
        { call: :remove_column, table: "now_no_key", name: "id" }
      ]}
    )
  end

  it "changes a table's primary key" do
    model(:alterkey) {
      fields primary_key: :t2 do |t|
        t.integer :t1, :t2
      end
    }

    table(:alterkey) { |t|
      t.primary_key :t1
      t.integer :t2
    }

    test_migrator(
      { change: [
        { call: :change_column, table: "alterkey", name: "t2", type: :primary_key},
        { call: :change_column, table: "alterkey", name: "t1", type: :integer}
      ]}
    )
  end

  it "renames columns where possible"
  it "renames tables where possible"

  it "automatically adds an index for references"
  it "automatically adds an index for foreign key"
  it "doesn't add an index if told not to"

  it "automatically names the migration if possible"
end
