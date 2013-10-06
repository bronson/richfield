# our ActiveRecord extension adding the fields method and
# the data structures to keep track of the results.

require 'richfield/fields'


module Richfield
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      # creates the field definitons if they haven't been created yet
      def richfield_fields_create
        # We need a single value shared by this class and all its children, but not any parents.
        # Can't use class @@vars since a single var is shared among all AR::Base children.
        # Can't use instance @vars alone since they're not inherited -- chilren can't see them.
        # Best I could come up with: parent uses instance var and children call through to parent.
        # I hate metaprogramming! A growler of Sante Adarius to anyone who can implement a better way.

        unless @_richfield_fields_defined
          if superclass.respond_to? :_richfield_fields
            class << self
              def _richfield_fields
                superclass._richfield_fields
              end
            end
          else
            class << self
              def _richfield_fields
                @_richfield_fields ||= Richfield::Fields.new(connection, table_name)
              end
            end
          end
        end

        # mark this class as having received the correct method
        @_richfield_fields_defined = true

        _richfield_fields
      end

      def richfield_fields
        self._richfield_fields if respond_to? :_richfield_fields
      end

      def fields options={}
        fields = richfield_fields_create
        fields.options.merge!(options)
        yield fields.definition if block_given?
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
