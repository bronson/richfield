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

  it "handles switching belongs_to ownership" do
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
        t.primary_key :id
      },
      table(:dogs) { |t|
        t.primary_key :id
        t.integer :handler_id
      },

      { change: [
        { call: :remove_column, table: "dogs",     name: "handler_id" },
        { call: :add_column,    table: "handlers", name: "dog_id", type: :integer }
      ]}
    )
  end

  it "adds a polymorphic association" do
    test_migrator(
      model(:comments) {
        fields do |t|
          t.text :content
        end
        belongs_to :commentable, polymorphic: true
      },

      table(:comments) { |t|
        t.primary_key :id
        t.text :content
      },

      { change: [
        { call: :add_column, table: "comments", name: "commentable_id", type: :integer},
        { call: :add_column, table: "comments", name: "commentable_type", type: :string, options: { limit: 255 }}
      ]}
    )
  end

  it "removes a polymorphic association" do
    test_migrator(
      model(:comments) {
        fields do |t|
          t.text :content
        end
      },

      table(:comments) { |t|
        t.primary_key :id
        t.text :content
        t.integer :commentable_id
        t.string :commentable_type
      },

      { change: [
        { call: :remove_column, table: "comments", name: "commentable_id" },
        { call: :remove_column, table: "comments", name: "commentable_type" }
      ]}
    )
  end

  it "adds a habtm table" do
    test_migrator(
      model(:users) {
        fields do |t|
          t.string :name
        end
        has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
      },

      model(:roles) {
        fields
        has_and_belongs_to_many :users, foreign_key: 'role_id', association_foreign_key: 'user_id', join_table: 'roles_users'
      },

      table(:users) { |t|
        t.primary_key :id
        t.string :name
      },

      table(:roles) { |t|
        t.primary_key :id
      },

      { create: [
        { table_name: "roles_users", primary_key: false, columns: [
          { name: "role_id", type: :integer },
          { name: "user_id", type: :integer }
        ]}
      ]}
    )
  end

  it "removes a habtm table" do
    test_migrator(
      model(:users) {
        fields do |t|
          t.string :name
        end
      },

      model(:roles) {
        fields
      },

      table(:users) { |t|
        t.primary_key :id
        t.string :name
      },

      table(:roles) { |t|
        t.primary_key :id
      },

      table(:roles_users) { |t|
        t.integer :role_id
        t.integer :user_id
      },

      { drop: [ "roles_users" ]}
    )
  end

  it "changes a column from an integer to a string" do
    test_migrator(
      model(:changing_table) {
        fields :id => false do |t|
          t.string :year
        end
      },
      table(:changing_table) { |t|
        t.integer :year
      },
      { change: [
        { call: :change_column, table: "changing_table", name: "year", type: :string, options: { limit: 255 }}
      ]}
    )
  end

  it "changes a column that's now :null => false" do
    test_migrator(
      model(:non_null) {
        fields :id => false do |t|
          t.string :name, :null => false
        end
      },
      table(:non_null) { |t|
        t.string :name
      },
      { change: [
        { call: :change_column, table: "non_null", name: "name", type: :string, options: { limit: 255, null: false }}
      ]}
    )
  end

  it "changes a column that's now :null => ok" do
    test_migrator(
      model(:nullable) {
        fields :id => false do |t|
          t.string :name
        end
      },
      table(:nullable) { |t|
        t.string :name, :null => false
      },
      { change: [
        { call: :change_column, table: "nullable", name: "name", type: :string, options: { limit: 255 }}
      ]}
    )
  end

  it "adds a table's primary key" do
    test_migrator(
      model(:now_with_key) {
        fields do |t|
          t.string :name
        end
      },
      table(:now_with_key) { |t|
        t.string :name
      },
      { change: [
        { call: :add_column, table: "now_with_key", name: "id", type: :primary_key }
      ]}
    )
  end

  it "removes a table's primary key" do
    test_migrator(
      model(:now_no_key) {
        fields id: false do |t|
          t.string :name
        end
      },
      table(:now_no_key) { |t|
        t.primary_key :id
        t.string :name
      },
      { change: [
        { call: :remove_column, table: "now_no_key", name: "id" }
      ]}
    )
  end

  it "changes a table's primary key" do
    test_migrator(
      model(:alterkey) {
        fields primary_key: :t2 do |t|
          t.integer :t1, :t2
        end
      },
      table(:alterkey) { |t|
        t.integer :t1, :t2
      },
      { }
    )
  end

  it "renames columns where possible"
  it "renames tables where possible"

  it "automatically adds an index for references"
  it "automatically adds an index for foreign key"
  it "doesn't add an index if told not to"

  it "automatically names the migration if possible"
end
