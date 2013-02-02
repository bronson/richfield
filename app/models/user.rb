class User < ActiveRecord::Base
  fields do |t|
    t.string :first_name
    t.string :last_name
    t.timestamps

    has_many :posts
  end
end
