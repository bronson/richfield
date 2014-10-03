## Richfield

A decreasingly brief experiment in making migrations write themselves.
Massive inspiration from Tom Locke and HoboFields.

[![Build Status](https://api.travis-ci.org/bronson/richfield.png?branch=master)](http://travis-ci.org/bronson/richfield)


## Compatibility

Rails 3 and Rails 4.  Ruby 1.9.3 and up.


## TODO






- Make Richfield understand reversible migrations:
  https://www.reinteractive.net/posts/178-reversible-migrations-with-active-record
  At the very least, pass the rest of the info to remove_column.
  NOTE: this must mean dropping Rails 3 support.
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
- Pass :index and :foreign_key into migration so schema_plus gem will work.
  Also, is it possible to ensure indices match, and generate a migration if not?
- Automatically add indexes (crib from https://github.com/plentz/lol_dba ?)
  Or can we just use lol_dba?
- add_column and remove_column should take a block that gets run
  after it is added and before it is removed.


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
