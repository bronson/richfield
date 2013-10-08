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
            @_richfield_fields_defined = :child
            _richfield_fields.using_sti!
          else
            class << self
              def _richfield_fields
                @_richfield_fields ||= Richfield::Fields.new(self)
              end
            end
            @_richfield_fields_defined = :base
          end
        end

        _richfield_fields
      end

      # true if this model is a child of another model using STI
      def richfield_is_sti_child?
        @_richfield_fields_defined == :child
      end


      # returns the declared field definitions
      def richfield_fields
        self._richfield_fields if respond_to? :_richfield_fields
      end

      # call this to declare your fields
      def fields options={}, &block
        richfield_fields_create.merge! options, block
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
