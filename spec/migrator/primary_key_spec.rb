require File.expand_path("../../spec_helper", __FILE__)

describe Richfield::Migrator do
  it "passes the primary key even when no fields defined" do
    model(:empty) { fields }
    test_migrator(
      { create: [
        { table_name: "empty", columns: [] }
      ]} )
  end


  it "adds a table's primary key" do
    model(:now_with_key) do
      fields do |t|
        t.string :name
      end
    end

    table(:now_with_key) do |t|
      t.string :name   # no id column
    end

    test_migrator(
      { change: [
        { call: :add_column, table: "now_with_key", name: "id", type: :primary_key }
      ]}
    )
  end


  it "removes a table's primary key when going id:false" do
    model(:now_no_key) do
      fields id: false do |t|
        t.string :name
      end
    end

    table(:now_no_key) do |t|
      t.primary_key :id
      t.string :name
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "now_no_key", name: "id" }
      ]})
  end


  it "removes a table's primary key when going primary_key:different" do
    model(:now_no_key) do
      fields primary_key: :zappo do |t|
        t.string :zappo
      end
    end

    table(:now_no_key) do |t|
      t.primary_key :id
      t.string :zappo
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "now_no_key", name: "id" }
      ]})
  end


  it "changes a table's primary key" do
    model(:alterkey) do
      fields primary_key: :t2 do |t|
        t.integer :t1, :t2
      end
    end

    table(:alterkey) do |t|
      t.primary_key :t1
      t.integer :t2
    end

    test_migrator({})
  end


  it "produces no changes with no id and different pk" do
    model(:nochange) do
      fields primary_key: :t2 do |t|
        t.integer :t2
      end
    end

    table(:nochange) do |t|
      t.primary_key :t2
    end

    test_migrator({})
  end
end
