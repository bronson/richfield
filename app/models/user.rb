class User < ActiveRecord::Base
  fields do |t|
    t.string :first_name
    t.string :last_name
    t.timestamps
  end

  has_and_belongs_to_many :posts
  has_many :posts
end
