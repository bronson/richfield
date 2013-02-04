# Testing table-oriented commands: create_table, drop_table, etc

require File.expand_path("../../spec_helper", __FILE__)

# TODO: get rid of limit:255 nonsense

describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    test_migrator(model(:ignored), {})
  end

  it "creates an primary key when no fields defined" do
    test_migrator(
      model(:empty) { fields },
      { create: [
        { table_name: "empty", primary_key: "id", columns: [
          { name: "id", type: :primary_key }    # still has primary key column
        ]}
      ]} )
  end

  it "creates a table with no columns when no fields and no primary key" do
    test_migrator(
      model(:truly_empty) { fields :id => false },
      { create: [{table_name: "truly_empty", primary_key: "id", columns: []} ]}
    )
  end

  it "creates simple unrelated tables" do
    test_migrator(
      model(:simple1) {
        fields do |t|
          t.string :first_name
          t.string :last_name, limit: 40
          t.timestamps
        end
      },

      model(:simple2) {
        fields primary_key: :i1 do |t|
          t.integer :i1, :i2, default: 0
          t.timestamps null: nil
        end
      },

      { create: [
        { table_name: "simple1", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "first_name", type: :string, limit: 255 },
          { name: "last_name", type: :string, limit: 40 },
          { name: "created_at", type: :datetime, :null => false },
          { name: "updated_at", type: :datetime, :null => false }
        ]},

        { table_name: "simple2", primary_key: "id", columns: [
          { name: "i1", type: :primary_key, default: 0 },
          { name: "i2", type: :integer, default: 0 },
          { name: "created_at", type: :datetime },
          { name: "updated_at", type: :datetime }
        ]}
      ]}
    )
  end

  it "handles a simple belongs_to association with relations in fields" do
    test_migrator(
      model(:handlers) {
        fields do |t|
          has_many :dogs
        end
      },

      model(:dogs) {
        fields do |t|
          belongs_to :handler
        end
      },

      { create: [
        { table_name: "dogs", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "handler_id", type: :integer }
        ]},

        { table_name: "handlers", primary_key: "id", columns: [
          { name: "id", type: :primary_key }
        ]}
      ]}
    )
  end

  it "handles a simple belongs_to association with relations in models" do
    test_migrator(
      model(:handlers) {
        fields
        has_many :dogs
      },
      model(:dogs) {
        fields
        belongs_to :handler
      },

      { create: [
        { table_name: "dogs", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "handler_id", type: :integer }
        ]},

        { table_name: "handlers", primary_key: "id", columns: [
          { name: "id", type: :primary_key }
        ]}
      ]}
    )
  end

  it "handles a polymorphic association" do
    test_migrator(
      model(:comments) {
        fields do |t|
          t.text :content
        end
        belongs_to :commentable, polymorphic: true
      },

      model(:articles) {
        fields do |t|
          t.string :name
        end
        has_many :comments, as: :commentable
      },

      { create: [
        { table_name: "articles", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "name", type: :string, limit: 255 },
        ]},

        { table_name: "comments", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "content", type: :text },
          { name: "commentable_id", type: :integer },
          { name: "commentable_type", type: :string, limit: 255 }
        ]}
      ]}
    )
  end

  it "creates a habtm table" do
    test_migrator(
      model(:users) {   # TODO: model should be specified like AR class name: 'User'
        fields do |t|
          t.string :name
        end
        # TODO: it's a shame we have to explicitly name all this stuff but, since we're using
        # anonymous classes, AR can't guess them.  Any way to fake a class name?
        has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
      },

      model(:roles) {
        fields
        has_and_belongs_to_many :users, foreign_key: 'role_id', association_foreign_key: 'user_id', join_table: 'roles_users'
      },

      { create: [
        { table_name: "roles", primary_key: "id", columns: [
          { name: "id", type: :primary_key }
        ]},

        { table_name: "roles_users", primary_key: false, columns: [
          { name: "role_id", type: :integer },
          { name: "user_id", type: :integer }
        ]},

        { table_name: "users", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "name", type: :string, limit: 255 }
        ]}
      ]}
    )
  end

  it "handles a has_many through association" do
    test_migrator(
      model(:physicians) {
        fields do |t|
          t.string :name
        end
        has_many :appointments
        has_many :patients, through: :appointments
      },

      model(:patients) {
        fields do |t|
          t.string :name
        end
        has_many :appointments
        has_many :physicians, through: :appointments
      },

      model(:appointments) {
        fields do |t|
          t.datetime :appointment_date
        end
        belongs_to :physician
        belongs_to :patient
      },

      { create: [
        { table_name: "appointments", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "appointment_date", type: :datetime },
          { name: "physician_id", type: :integer },
          { name: "patient_id", type: :integer }
        ]},

        { table_name: "patients", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "name", type: :string, limit: 255 }
        ]},

        { table_name: "physicians", primary_key: "id", columns: [
          { name: "id", type: :primary_key },
          { name: "name", type: :string, limit: 255 }
        ]}
      ]}
    )
  end

  it "creates an sti table"

  it "drops tables" do
    test_migrator(
      # no models
      table('ravens') { |t|
        t.string :first
      },
      table('empties') { |t|
        t.string :name
      },
      { drop: [ 'empties', 'ravens' ]}
    )
  end

  it "drops a habtm join table"
end
