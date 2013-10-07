## Richfield

A decreasingly brief experiment in making migrations write themselves.
Massive inspiration from Tom Locke and HoboFields.

[![Build Status](https://api.travis-ci.org/bronson/richfield.png?branch=master)](http://travis-ci.org/bronson/richfield)

## Droppings

Q: Can I set custom options on relations columns?  For example, `belongs_to :user, default: 12`

A: No, the belongs_to must be pure ActiveRecord.  However, you can always define
it however you'd like in your fields statement.  Richfield won't override you.

    class Permission < ActiveRecord::Base
      belongs_to :user
      fields do |t|
        t.integer :user_id, default: 12
      end
    end

## License

Pain-free MIT
