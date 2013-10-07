# stores all the information from a fields { } block

require 'richfield/compatibility'


module Richfield
  class Fields
    attr_reader :definition
    attr_reader :options

    def initialize(connection, table_name)
      @definition = Richfield::Compatibility.create_table_definition(connection, table_name)
      @options = {}
      @sti = false
    end

    def columns
      @definition.columns
    end

    # invoked when a fields block gets used in a subclass
    def using_sti!
      @sti = true
    end

    def using_sti?
      @sti
    end
  end
end
