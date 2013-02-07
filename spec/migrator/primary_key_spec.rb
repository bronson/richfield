require File.expand_path("../../spec_helper", __FILE__)

describe Richfield::Migrator do
  it "passes the primary key even when no fields defined" do
    model 'Empty' do
      fields
    end

    test_migrator(
      { create: [
        { table_name: "empties", columns: [] }
      ]} )
  end


  it "adds a table's primary key" do
    model 'NowWithKeys' do
      fields do |t|
        t.string :name
      end
    end

    table :now_with_keys do |t|
      t.string :name   # no id column
    end

    test_migrator(
      { change: [
        { call: :add_column, table: "now_with_keys", name: "id", type: :primary_key }
      ]}
    )
  end


  it "removes a table's primary key when going id:false" do
    model 'NowNoKey' do
      fields id: false do |t|
        t.string :name
      end
    end

    table :now_no_keys do |t|
      t.primary_key :id
      t.string :name
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "now_no_keys", name: "id" }
      ]})
  end


  it "removes a table's primary key when going primary_key:different" do
    model 'NowNoKey' do
      fields primary_key: :zappo do |t|
        t.string :zappo
      end
    end

    table :now_no_keys do |t|
      t.primary_key :id
      t.string :zappo
    end

    test_migrator({
      change: [
        { call: :remove_column, table: "now_no_keys", name: "id" }
      ]})
  end


  it "changes a table's primary key" do
    model 'AlterKey' do
      fields primary_key: :t2 do |t|
        t.integer :t1, :t2
      end
    end

    table :alter_keys do |t|
      t.primary_key :t1
      t.integer :t2
    end

    test_migrator({})
  end


  it "produces no changes with no id and different pk" do
    model 'NoChange' do
      fields primary_key: :t2 do |t|
        t.integer :t2
      end
    end

    table :no_changes do |t|
      t.primary_key :t2
    end

    test_migrator({})
  end
end
