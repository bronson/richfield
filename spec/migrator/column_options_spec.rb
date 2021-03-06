require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  describe "limit column option" do
    it "works for string and text fields"
    it "works for integer fields"
      # mysql :integer has a default limit of 4, sqlite has no default
    it "works for binary fields"  # limit: 2.megabytes, limit: 3.terabytes
    it "works for boolean fields"
      # mysql implements boolean as a tinyint with limit 1
    it "shows what happens if we apply it to other columns"
  end


  describe "precision and scale column options" do
    it "correctly applies to decimal columns"
    it "correctly assumes scale:0 is the same as no scale"
    it "shows what happens if we apply it to other columns"
  end


  describe "default column option" do
    it "correctly handles simple defaults"
    # integer, String, true, false, boolean 1, boolean 0
    it "correctly treats default:nil as no default"
    it "displays a BigDecimal correctly"
    it "displays the correctly formatted date"
    # Date DateTime Time
  end


  describe "null column option" do
    it "changes a column that's now :null => false" do
      model 'NonNull' do
        fields :id => false do |t|
          t.string :name, :null => false
        end
      end

      table :non_nulls do |t|
        t.string :name
      end

      expect(generated_migration).to eq({
        change: [
          { call: :change_column, table: "non_nulls", name: "name", type: :string, options: { null: false }}
        ]} )
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

      expect(generated_migration).to eq({
        change: [
          { call: :change_column, table: "nullables", name: "name", type: :string }
        ]} )
    end


    it "ignores a model column that's :null => true" do
      model 'Nullable' do
        fields :id => false do |t|
          t.string :name, null: true
        end
      end

      table :nullables do |t|
        t.string :name
      end

      expect(generated_migration).to eq({})
    end


    it "ignores a table column that's :null => true" do
      model 'Nullable' do
        fields :id => false do |t|
          t.string :name
        end
      end

      table :nullables do |t|
        t.string :name, null: true
      end

      expect(generated_migration).to eq({})
    end
  end


  it "shows what happens if we specify an option that doesn't exist"
  it "handles a mess of options all at once"
end
