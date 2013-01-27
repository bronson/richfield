module Richfield
  module ActiveRecord
    module Base
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :model_fields

        def fields include_in_migration=true, &block
          @include_in_migration = include_in_migration
          Dsl.new(self).instance_eval(&block)
        end

        def declare_field name, *args
          @model_fields ||= {}
          @model_fields[name] = args
        end
      end
    end
  end

  class Dsl < BasicObject
    def initialize model
      @model = model
    end

    def field name, type, *args
      @model.declare_field name, type, *args
    end

    def method_missing name, *args
      field name, args[0], *args[1..-1]
    end

    def timestamps
      field :created_at, :datetime
      field :updated_at, :datetime
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecord::Base
