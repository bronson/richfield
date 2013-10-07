# Testing Single Table Inheritance

require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do

  it "handles an sti table" do
    model 'Asset' do
      fields do |t|
        t.integer :price
      end
    end

    model 'Property', Asset do
      fields do |t|
        t.integer :ceiling_height
      end
    end

    model 'Land', Asset do
      fields do |t|
        t.integer :easements
      end
    end

    test_migrator(
      { create: [
        { table_name: "assets", columns: [
          { name: "price", type: :integer },
          { name: "ceiling_height", type: :integer },
          { name: "easements", type: :integer },
          { name: "type", type: :string, null: false } # automatically added
        ]}
      ]}
    )
  end


  it "handles an sti table with a different type column" do
    model 'Enemy' do
      self.inheritance_column = 'zoink'
      fields do |t|
        t.integer :flaws
      end
    end

    model 'Clown', Enemy do
      fields do |t|
        t.integer :psychoses
      end
    end

    test_migrator(
      { create: [
        { table_name: "enemies", columns: [
          { name: "flaws", type: :integer },
          { name: "psychoses", type: :integer },
          { name: "zoink", type: :string, null: false },
        ]}
      ]}
    )
  end


  it "won't override sti table's declared type column" do
    model 'Enemy' do
      self.inheritance_column = 'zoink'
      fields do |t|
        t.text    :zoink
        t.integer :flaws
      end
    end

    model 'Clown', Enemy do
      fields do |t|
        t.integer :psychoses
      end
    end

    table "enemies" do |t|
      t.integer :id
      t.text    :zoink
      t.integer :flaws
      t.integer :psychoses
    end

    test_migrator( {} )  # table matches models, nothing to do
  end

  # doh, the proper way to implement this is to add the
  # functionality to AR::CA::TableDefinition.  On hold for now.

  # it "detects base-child sti conflicts" do
  #   model 'Asset' do
  #     fields do |t|
  #       t.string :name
  #       t.integer :price
  #     end
  #   end

  #   model 'Property', Asset do
  #     fields do |t|
  #       t.integer :price   # conflicts with Asset.price
  #     end
  #   end

  #   model 'Land', Asset do
  #     fields do |t|
  #       t.integer :easements
  #     end
  #   end

  #   expect { test_migrator }.to raise_error(NameError)
  # end


  # it "detects child-child sti conflicts" do
  #   model 'Asset' do
  #     fields do |t|
  #       t.string :name
  #     end
  #   end

  #   model 'Property', Asset do
  #     fields do |t|
  #       t.integer :price
  #     end
  #   end

  #   model 'Land', Asset do
  #     fields do |t|
  #       t.integer :price   # conflicts with Property.price
  #     end
  #   end

  #   expect { test_migrator }.to raise_error(NameError)
  # end
end
