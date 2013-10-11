require File.expand_path("../../spec_helper", __FILE__)


describe Richfield::Migrator do
  it "correctly guesses the foreign key" do
    model "Artist" do
      has_many :shows
      fields do |t|
        t.string :name
      end
    end

    model "Show" do
      belongs_to :artist
      fields do |t|
        t.datetime :showtime
      end
    end

    test_migrator({
      create: [{
        table_name: "artists",
        columns: [
          { type: :string, name: "name" }
        ]
      }, {
        table_name: "shows",
        columns: [
          { type: :datetime, name: "showtime" },
          { type: :integer, name: "artist_id" }
        ]
      }]
    })
  end

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
