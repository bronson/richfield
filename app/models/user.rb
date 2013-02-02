class User < ActiveRecord::Base
  fields do |t|
    t.string :first_name, :limit => 40
    t.string :last_name, :null => false, :precision => 10
    t.timestamps
  end
end
