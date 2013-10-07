# Testing Single Table Inheritance

require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do

  it "handles an sti table" do
    model 'Asset' do
      fields do |t|
        t.string :name
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
          { name: "name", type: :string },
          { name: "price", type: :integer },
          { name: "ceiling_height", type: :integer },
          { name: "easements", type: :integer }
        ]}
      ]}
    )
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
