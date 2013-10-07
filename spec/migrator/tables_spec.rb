# Testing table-oriented commands: create_table, drop_table, etc

require File.expand_path("../../spec_helper", __FILE__)


# TODO: test that adding a belongs_to doesn't incorrectly add fields to a
# model that never asked for fields.

describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    model 'Ignored'
    test_migrator({})
  end


  it "ignores tables that are ignored", focus:true do
    pending "mocking tables and models, then testing the generator itself"
    Richfield.config.ignore_tables << 'ignore_me'
    table :ignore_me
    test_migrator({})
  end


  it "creates a table with no columns when no fields and no primary key" do
    model 'TrulyEmpty' do
      fields :id => false
    end

    test_migrator(
      { create: [{table_name: "truly_empties", options: {id: false}, columns: []} ]}
    )
  end


  it "creates simple unrelated tables" do
    model 'FirstSimple' do
      fields do |t|
        t.string :first_name
        t.string :last_name, limit: 40
        t.timestamps null: false   # specify nullability since AR3 and AR4 defaults are different
      end
    end

    model 'SecondSimple' do
      fields primary_key: :i1 do |t|
        t.integer :i1, :i2, default: 0
        t.timestamps null: true   # specify nullability since AR3 and AR4 defaults are different
      end
    end

    test_migrator(
      { create: [
        { table_name: "first_simples", columns: [
          { name: "first_name", type: :string },
          { name: "last_name", type: :string, limit: 40 },
          { name: "created_at", type: :datetime, :null => false },
          { name: "updated_at", type: :datetime, :null => false }
        ]},

        { table_name: "second_simples", options: {primary_key: :i1}, columns: [
          { name: "i1", type: :integer, default: 0 },
          { name: "i2", type: :integer, default: 0 },
          { name: "created_at", type: :datetime },
          { name: "updated_at", type: :datetime }
        ]}
      ]}
    )
  end


  it "handles multiple fields declarations in a single model" do
    model 'MultiModal' do
      fields { |t| t.string :first_name }
      # ensure table options are merged too
      fields(id: false) { |t| t.string :last_name, limit: 40 }
      fields { |t| t.integer :age }
    end

    test_migrator(
      { create: [
        { table_name: "multi_modals", options: {id: false}, columns: [
          { name: "first_name", type: :string },
          { name: "last_name", type: :string, limit: 40 },
          { name: "age", type: :integer }
        ]}
      ]}
    )
  end


  it "handles a simple belongs_to association with relations in fields" do
    model 'Handler' do
      fields do |t|
        has_many :dogs
      end
    end

    model 'Dog' do
      fields do |t|
        belongs_to :handler
      end
    end

    test_migrator(
      { create: [
        { table_name: "dogs", columns: [
          { name: "handler_id", type: :integer }
        ]},

        { table_name: "handlers", columns: [
        ]}
      ]}
    )
  end


  it "handles a simple belongs_to association with relations in models" do
    model 'Handler' do
      fields
      has_many :dogs
    end

    model 'Dog' do
      fields
      belongs_to :handler
    end

    test_migrator(
      { create: [
        { table_name: "dogs", columns: [
          { name: "handler_id", type: :integer }
        ]},
        { table_name: "handlers", columns: []}
      ]}
    )
  end


  it "handles a polymorphic association" do
    model 'Comment' do
      fields do |t|
        t.text :content
      end
      belongs_to :commentable, polymorphic: true
    end

    model 'Article' do
      fields do |t|
        t.string :name
      end
      has_many :comments, as: :commentable
    end

    test_migrator(
      { create: [
        { table_name: "articles", columns: [
          { name: "name", type: :string },
        ]},

        { table_name: "comments", columns: [
          { name: "content", type: :text },
          { name: "commentable_id", type: :integer },
          { name: "commentable_type", type: :string }
        ]}
      ]}
    )
  end


  it "creates a habtm table" do
    model 'User' do   # TODO: model should be specified like AR class name: 'User'
      fields do |t|
        t.string :name
      end
      # TODO: it's a shame we have to explicitly name all this stuff but, since we're using
      # anonymous classes, AR can't guess them.  Any way to fake a class name?
      has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
    end

    model 'Role' do
      fields
      has_and_belongs_to_many :users, foreign_key: 'role_id', association_foreign_key: 'user_id', join_table: 'roles_users'
    end

    test_migrator(
      { create: [
        { table_name: "roles", columns: []},

        { table_name: "roles_users", options: {id: false}, columns: [
          { name: "role_id", type: :integer },
          { name: "user_id", type: :integer }
        ]},

        { table_name: "users", columns: [
          { name: "name", type: :string }
        ]}
      ]}
    )
  end


  it "handles a has_many through association" do
    model 'Physician' do
      fields do |t|
        t.string :name
      end
      has_many :appointments
      has_many :patients, through: :appointments
    end

    model 'Patient' do
      fields do |t|
        t.string :name
      end
      has_many :appointments
      has_many :physicians, through: :appointments
    end

    model 'Appointment' do
      fields do |t|
        t.datetime :appointment_date
      end
      belongs_to :physician
      belongs_to :patient
    end

    test_migrator(
      { create: [
        { table_name: "appointments", columns: [
          { name: "appointment_date", type: :datetime },
          { name: "physician_id", type: :integer },
          { name: "patient_id", type: :integer }
        ]},

        { table_name: "patients", columns: [
          { name: "name", type: :string }
        ]},

        { table_name: "physicians", columns: [
          { name: "name", type: :string }
        ]}
      ]}
    )
  end



  it "drops tables" do
    # no models

    table :ravens do |t|
      t.string :first
    end

    table :empties do |t|
      t.string :name
    end

    test_migrator(
      { drop: [ 'empties', 'ravens' ]}
    )
  end

  it "drops a habtm join table"
end
