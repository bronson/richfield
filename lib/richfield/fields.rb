# stores all the information from a fields { } block

require 'richfield/compatibility'


# The only notable thing about this class is, if you try to merge some fields
# before the database connection is open, it will save them until the connection
# is opened later. We need an open connection to create a TableDefinition (it
# needs the connection's native_database_types), but we don't want to connect
# when the class is simply being loaded.  (bad form and incompatible with Heroku Cedar)

module Richfield
  class Fields
    attr_reader :options

    def initialize model
      @definition = nil   # the TableDefinition
      @model = model
      @options = {}
      @sti = false
      @deferred = []      # options and blocks awaiting a db connection
    end

    # invoked when a fields block gets used in a subclass
    def using_sti!
      @sti = true
    end

    def using_sti?
      @sti
    end

    def definition
      instantiate!
      @definition
    end

    def columns
      definition.columns
    end

    def _merge opts, block
      self.options.merge!(opts)
      block && block.call(@definition)
    end

    def merge! opts, block
      if @model.connected?
        instantiate!
        _merge opts, block
      else
        @deferred.push [opts, block]
      end
    end

    def instantiate!
      return if @definition
      @definition = Richfield::Compatibility.create_table_definition(@model.connection, @model.table_name)
      @deferred.each { |args| _merge(*args) }
      @deferred = nil
    end
  end
end
