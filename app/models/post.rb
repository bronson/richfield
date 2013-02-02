class Post < ActiveRecord::Base
  fields do |t|
    t.string :name
    t.string :title
    t.text :content
    t.timestamps
  end

  belongs_to :user
  attr_accessible :content, :name, :title
end
