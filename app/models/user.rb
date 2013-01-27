class User < ActiveRecord::Base
  fields do |t|
    t.first_name :string
    t.last_name :string
    t.timestamps
  end
end
