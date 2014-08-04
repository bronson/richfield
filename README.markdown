## Richfield

A decreasingly brief experiment in making migrations write themselves.
Massive inspiration from Tom Locke and HoboFields.

[![Build Status](https://api.travis-ci.org/bronson/richfield.png?branch=master)](http://travis-ci.org/bronson/richfield)


## Compatibility

Rails 3 and Rails 4.  Ruby 1.9.3 and up.


## TODO

Before this gem is ready for prime time:

- get rid of Richfield::TableDefinition
- implement down migrations
- don't ignore existing migration syntax.  if I specify some options on the command line, they should be added to the generated migration.
- implement pending specs
- be smart about renaming fields and tables instead of adding/dropping
- if the model specifies self.primary_key = :blah, why do I also have to pass it in the fields block?
- try to fix tods
- document document document!
- add code to guess the name of the migration?
- add ability to set config from command line (pending_migration check)
- if reversable, coalesce up/down block into change block?
- release 1.0
- submit patch so Richfield::SchemaFormatter can take over from the more limited AR::SchemaDumper


## Droppings

Q: Can I set custom options on relations columns?  For example, `belongs_to :user, default: 12`

A: No, the belongs_to must be pure ActiveRecord.  However, you can always define
it however you'd like in your fields statement.  Richfield won't override you.

    class Permission < ActiveRecord::Base
      belongs_to :user
      fields do |t|
        t.integer :user_id, default: 1
      end
    end


## License

Pain-free MIT
