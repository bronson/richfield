require File.expand_path("../spec_helper", __FILE__)


describe Richfield::SchemaFormatter do
  it "dumps create_table" do
  	table :dump_me do |t|
  	  t.string :name   # no id column
  	end

  	output = Richfield::Migrator::Output.new(@tables, [], [])
    expect(output.up_body ' '*6).to eq <<-EOL
      create_table :dump_me, {:force=>true} do |t|
        t.string "name"
      end
    EOL
  end
end
