# Testing column-oriented commands: add_column, remove_column, change_column, etc

require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  it "adds a type column when sti is used"   # when subclasses exist but they don't declare any fields
  it "handles fields declarations in sti subclasses"   # when subclasses declare fields


  it "adds a column to a truly empty table" do
    model 'Empty' do
      fields :id => false do |t|
        t.string :name, :default => "nope"
      end
    end

    table :empties do
    end

    test_migrator({
      change: [
        { call: :add_column, table: 'empties', name: 'name', type: :string, options: { default: "nope" } }
      ]})
  end


  it "handles switching belongs_to ownership" do
    model 'Handler' do
      fields
      belongs_to :dog
    end

    model 'Dog' do
      fields
      has_many :handlers
    end

    table :handlers do |t|
      t.primary_key :id
    end

    table :dogs do |t|
      t.primary_key :id
      t.integer :handler_id
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "dogs",     name: "handler_id" },
        { call: :add_column,    table: "handlers", name: "dog_id", type: :integer }
      ]})
  end


  it "handles a reflexive association" do
    model 'Sector' do
      fields
      belongs_to :parent_assoc, :class_name => 'Sector', :foreign_key => 'parent_id'
    end

    table 'sectors' do |t|
      t.primary_key :id
    end

    test_migrator({
      change: [
        { call: :add_column, table: "sectors", name: "parent_id", type: :integer }
      ]})
  end

  it "adds a polymorphic association" do
    model 'Comment' do
      fields do |t|
        t.text :content
      end
      belongs_to :commentable, polymorphic: true
    end

    table :comments do |t|
      t.primary_key :id
      t.text :content
    end

    test_migrator({
      change: [
        { call: :add_column, table: "comments", name: "commentable_id", type: :integer},
        { call: :add_column, table: "comments", name: "commentable_type", type: :string }
      ]})
  end


  it "removes a polymorphic association" do
    model 'Comment' do
      fields do |t|
        t.text :content
      end
    end

    table :comments do |t|
      t.primary_key :id
      t.text :content
      t.integer :commentable_id
      t.string :commentable_type
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "comments", name: "commentable_id" },
        { call: :remove_column, table: "comments", name: "commentable_type" }
      ]})
  end


  it "adds a habtm table when just assoc is changed", focus:true do
    model 'User' do
      fields do |t|
        t.string :name
      end
      # TODO: why doesn't this work?
      has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
    end

    model 'Role' do
      fields
      has_and_belongs_to_many :users, foreign_key: 'role_id', association_foreign_key: 'user_id', join_table: 'roles_users'
    end

    table(:users) do |t|
      t.primary_key :id
      t.string :name
    end

    table(:roles) do |t|
      t.primary_key :id
    end

    test_migrator({
      create: [
        { table_name: "roles_users", options: {id: false}, columns: [
          { name: "role_id", type: :integer },
          { name: "user_id", type: :integer }
        ]}
      ]})
  end


  it "removes a habtm table when just assoc is changed" do
    model 'User' do
      fields do |t|
        t.string :name
      end
    end

    model 'Role' do
      fields
    end

    table :users do |t|
      t.primary_key :id
      t.string :name
    end

    table :roles do |t|
      t.primary_key :id
    end

    table :roles_users do |t|
      t.integer :role_id
      t.integer :user_id
    end

    test_migrator({
      drop: [ "roles_users" ]
    })
  end


  it "changes a column from an integer to a string" do
    model 'ChangingTable' do
      fields :id => false do |t|
        t.string :year
      end
    end

    table :changing_tables do |t|
      t.integer :year
    end

    test_migrator({
      change: [
        { call: :change_column, table: "changing_tables", name: "year", type: :string }
      ]})
  end


  it "changes a column that's now :null => false" do
    model 'NonNull' do
      fields :id => false do |t|
        t.string :name, :null => false
      end
    end

    table :non_nulls do |t|
      t.string :name
    end

    test_migrator({
      change: [
        { call: :change_column, table: "non_nulls", name: "name", type: :string, options: { null: false }}
      ]})
  end


  it "changes a column that's no longer :null => false" do
    model 'Nullable' do
      fields :id => false do |t|
        t.string :name  # null is default
      end
    end

    table :nullables do |t|
      t.string :name, :null => false
    end

    test_migrator({
      change: [
        { call: :change_column, table: "nullables", name: "name", type: :string }
      ]})
  end


  # TODO: shouldn't nullability match?
  it "ignores a model column that's :null => true" do
    model 'Nullable' do
      fields :id => false do |t|
        t.string :name, null: true
      end
    end

    table :nullables do |t|
      t.string :name
    end

    test_migrator({})
  end


  # TODO: shouldn't nullability match?
  it "ignores a table column that's :null => true" do
    model 'Nullable' do
      fields :id => false do |t|
        t.string :name
      end
    end

    table :nullables do |t|
      t.string :name, null: true
    end

    test_migrator({})
  end

  it "renames columns where possible"
  it "renames tables where possible"

  it "automatically adds an index for references"
  it "automatically adds an index for foreign key"
  it "doesn't add an index if told not to"

  it "automatically names the migration if possible"
end
