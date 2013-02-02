class Post < ActiveRecord::Base
  fields do |t|
    t.string :name
    t.string :title
    t.text :content
    t.timestamps
  end

  has_and_belongs_to_many :users
  attr_accessible :content, :name, :title
end
