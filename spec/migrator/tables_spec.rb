# Testing table-oriented commands: create_table, drop_table, etc

require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  it "ignores models that don't declare fields" do
    model(:ignored)
    test_migrator({})
  end

  it "creates a table with no columns when no fields and no primary key" do
    model(:truly_empty) { fields :id => false }
    test_migrator(
      { create: [{table_name: "truly_empty", options: {id: false}, columns: []} ]}
    )
  end

  it "creates simple unrelated tables" do
    model(:simple1) do
      fields do |t|
        t.string :first_name
        t.string :last_name, limit: 40
        t.timestamps
      end
    end

    model(:simple2) do
      fields primary_key: :i1 do |t|
        t.integer :i1, :i2, default: 0
        t.timestamps null: nil
      end
    end

    test_migrator(
      { create: [
        { table_name: "simple1", columns: [
          { name: "first_name", type: :string },
          { name: "last_name", type: :string, limit: 40 },
          { name: "created_at", type: :datetime, :null => false },
          { name: "updated_at", type: :datetime, :null => false }
        ]},

        { table_name: "simple2", options: {primary_key: :i1}, columns: [
          { name: "i1", type: :integer, default: 0 },
          { name: "i2", type: :integer, default: 0 },
          { name: "created_at", type: :datetime },
          { name: "updated_at", type: :datetime }
        ]}
      ]}
    )
  end

  it "handles a simple belongs_to association with relations in fields" do
    model(:handlers) do
      fields do |t|
        has_many :dogs
      end
    end

    model(:dogs) do
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
    model(:handlers) do
      fields
      has_many :dogs
    end

    model(:dogs) do
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
    model(:comments) do
      fields do |t|
        t.text :content
      end
      belongs_to :commentable, polymorphic: true
    end

    model(:articles) do
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
    model(:users) do   # TODO: model should be specified like AR class name: 'User'
      fields do |t|
        t.string :name
      end
      # TODO: it's a shame we have to explicitly name all this stuff but, since we're using
      # anonymous classes, AR can't guess them.  Any way to fake a class name?
      has_and_belongs_to_many :roles, foreign_key: 'user_id', association_foreign_key: 'role_id', join_table: 'roles_users'
    end

    model(:roles) do
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
    model(:physicians) do
      fields do |t|
        t.string :name
      end
      has_many :appointments
      has_many :patients, through: :appointments
    end

    model(:patients) do
      fields do |t|
        t.string :name
      end
      has_many :appointments
      has_many :physicians, through: :appointments
    end

    model(:appointments) do
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

  it "creates an sti table"

  it "drops tables" do
    # no models
    table('ravens') { |t|
      t.string :first
    }
    table('empties') { |t|
      t.string :name
    }

    test_migrator(
      { drop: [ 'empties', 'ravens' ]}
    )
  end

  it "drops a habtm join table"
end
