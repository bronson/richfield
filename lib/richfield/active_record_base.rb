module Richfield
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :richfield_table_options

      def richfield_definition vivify=true
        @richfield_definiton ||= (vivify ? ActiveRecord::ConnectionAdapters::TableDefinition.new(connection) : nil)
      end

      def fields options={}
        cols = richfield_definition
        @richfield_table_options = options
        yield cols if block_given?
      end

      # todo: will anybody use this?  should delete it?
      # def add_column name, type, options={}
      #   richfield_definition.column name, type, options
      # end

      def belongs_to name, options={}, &block
        super name, options, &block
        richfield_definition.references name, options
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
