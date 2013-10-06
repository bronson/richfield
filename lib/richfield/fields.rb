# stores all the information from a fields { } block

require 'richfield/compatibility'


module Richfield
  class Fields
    attr_reader :definition
    attr_reader :options

    def initialize(connection, table_name)
      @definition = Richfield::Compatibility.create_table_definition(connection, table_name)
      @options = {}
    end

    def columns
      @definition.columns
    end
  end
end
