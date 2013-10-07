require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  it "uses the foreign key you define" do
    model "Contact" do
      fields id: false
    end

    model "Asset" do
      belongs_to :contact_one, class_name: 'Contact', foreign_key: :contact_one
      fields do |t|
        t.string "contact_one"   # the belongs_to implies an integer fk so override that
      end
    end

    table "contacts"

    test_migrator({
      :create => [{
        :table_name=>"assets",
        :columns=>[
          { :type=>:string, :name=>"contact_one" }   # string, as defined in the fields block
        ]}
      ]}
    )
  end
end
